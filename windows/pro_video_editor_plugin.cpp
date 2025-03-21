#include "pro_video_editor_plugin.h"

#include <windows.h>
#include <VersionHelpers.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <comdef.h>
#include <shlwapi.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <sstream>
#include <vector>
#include <wincodec.h> 
#include <initguid.h>

#pragma comment(lib, "mfplat.lib")
#pragma comment(lib, "mfreadwrite.lib")
#pragma comment(lib, "mfuuid.lib")
#pragma comment(lib, "shlwapi.lib")

namespace pro_video_editor {

	void ProVideoEditorPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarWindows* registrar) {
		auto channel =
			std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
				registrar->messenger(), "pro_video_editor",
				&flutter::StandardMethodCodec::GetInstance());

		auto plugin = std::make_unique<ProVideoEditorPlugin>();

		channel->SetMethodCallHandler(
			[plugin_pointer = plugin.get()](const auto& call, auto result) {
				plugin_pointer->HandleMethodCall(call, std::move(result));
			});

		registrar->AddPlugin(std::move(plugin));
	}

	ProVideoEditorPlugin::ProVideoEditorPlugin() {
		// Initialize Media Foundation
		HRESULT hr = MFStartup(MF_VERSION);
		if (FAILED(hr)) {
			OutputDebugString(L"Failed to initialize Media Foundation");
		}
	}

	ProVideoEditorPlugin::~ProVideoEditorPlugin() {
		MFShutdown();
	}

	void ProVideoEditorPlugin::HandleMethodCall(
		const flutter::MethodCall<flutter::EncodableValue>& method_call,
		std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
		if (method_call.method_name().compare("getPlatformVersion") == 0) {
			std::ostringstream version_stream;
			version_stream << "Windows ";
			if (IsWindows10OrGreater()) {
				version_stream << "10+";
			}
			else if (IsWindows8OrGreater()) {
				version_stream << "8";
			}
			else if (IsWindows7OrGreater()) {
				version_stream << "7";
			}
			result->Success(flutter::EncodableValue(version_stream.str()));
		}
		else if (method_call.method_name().compare("getVideoInformation") == 0) {
			const auto* video_data = std::get_if<std::vector<uint8_t>>(method_call.arguments());
			if (!video_data) {
				result->Error("Invalid argument", "Expected Uint8List");
				return;
			}

			// Create a temporary file
			wchar_t temp_path[MAX_PATH];
			GetTempPathW(MAX_PATH, temp_path);
			wchar_t temp_file[MAX_PATH];
			GetTempFileNameW(temp_path, L"vid", 0, temp_file);

			HANDLE file_handle = CreateFileW(temp_file, GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
			if (file_handle == INVALID_HANDLE_VALUE) {
				result->Error("FileError", "Failed to create temp file");
				return;
			}

			DWORD bytes_written;
			if (!WriteFile(file_handle, video_data->data(), static_cast<DWORD>(video_data->size()), &bytes_written, nullptr)) {
				CloseHandle(file_handle);
				DeleteFileW(temp_file);
				result->Error("FileError", "Failed to write to temp file");
				return;
			}
			CloseHandle(file_handle);


			// Open the file again in read mode to get the file size
			file_handle = CreateFileW(temp_file, GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
			if (file_handle == INVALID_HANDLE_VALUE) {
				DeleteFileW(temp_file);
				result->Error("FileError", "Failed to open temp file for reading size");
				return;
			}

			// Get file size
			LARGE_INTEGER file_size;
			if (!GetFileSizeEx(file_handle, &file_size)) {
				CloseHandle(file_handle);
				DeleteFileW(temp_file);
				result->Error("FileError", "Failed to get file size");
				return;
			}
			CloseHandle(file_handle);  // Close after reading size

			// Media Foundation setup
			IMFSourceReader* source_reader = nullptr;
			IMFAttributes* attributes = nullptr;
			HRESULT hr = MFCreateAttributes(&attributes, 1);
			if (FAILED(hr)) {
				DeleteFileW(temp_file);
				result->Error("MediaError", "Failed to create attributes");
				return;
			}

			hr = MFCreateSourceReaderFromURL(temp_file, attributes, &source_reader);
			attributes->Release();
			if (FAILED(hr)) {
				DeleteFileW(temp_file);
				result->Error("MediaError", "Failed to create source reader");
				return;
			}

			// Get duration
			PROPVARIANT duration_var;
			PropVariantInit(&duration_var);
			double duration_ms = 0.0; // Duration in milliseconds

			hr = source_reader->GetPresentationAttribute(static_cast<DWORD>(MF_SOURCE_READER_MEDIASOURCE), MF_PD_DURATION, &duration_var);
			if (SUCCEEDED(hr) && duration_var.vt == VT_UI8) {
				duration_ms = static_cast<double>(duration_var.uhVal.QuadPart) / 10'000; // Convert to milliseconds
			}
			PropVariantClear(&duration_var);

			// Get MIME type (format)
			PROPVARIANT mime_var;
			PropVariantInit(&mime_var);
			std::string format = "unknown";
#pragma warning(push)
#pragma warning(disable:4245)
			hr = source_reader->GetPresentationAttribute(static_cast<DWORD>(MF_SOURCE_READER_MEDIASOURCE), MF_PD_MIME_TYPE, &mime_var);
#pragma warning(pop)
			if (SUCCEEDED(hr) && mime_var.vt == VT_LPWSTR) {
				char mime_buffer[256];
				WideCharToMultiByte(CP_UTF8, 0, mime_var.pwszVal, -1, mime_buffer, 256, nullptr, nullptr);
				format = mime_buffer;
				// Simplify MIME type (e.g., "video/mp4" -> "mp4")
				size_t slash = format.find('/');
				if (slash != std::string::npos) {
					format = format.substr(slash + 1);
				}
			}
			PropVariantClear(&mime_var);


			// Get video resolution (width & height)
			UINT32 width = 0, height = 0;
			IMFMediaType* media_type = nullptr;
			hr = source_reader->GetNativeMediaType((DWORD)MF_SOURCE_READER_FIRST_VIDEO_STREAM, 0, &media_type);
			if (SUCCEEDED(hr) && media_type) {
				MFGetAttributeSize(media_type, MF_MT_FRAME_SIZE, &width, &height);
				media_type->Release();
			}

			// Cleanup
			source_reader->Release();
			DeleteFileW(temp_file);

			// Return result
			flutter::EncodableMap result_map;
			result_map[flutter::EncodableValue("duration")] = flutter::EncodableValue(duration_ms);
			result_map[flutter::EncodableValue("format")] = flutter::EncodableValue(format);
			result_map[flutter::EncodableValue("width")] = flutter::EncodableValue(static_cast<int>(width));
			result_map[flutter::EncodableValue("height")] = flutter::EncodableValue(static_cast<int>(height));
			result_map[flutter::EncodableValue("fileSize")] = flutter::EncodableValue(static_cast<int64_t>(file_size.QuadPart));
			result->Success(flutter::EncodableValue(result_map));
		}
		else if (method_call.method_name().compare("createVideoThumbnails") == 0) {
			const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
			if (!args) {
				result->Error("InvalidArgument", "Expected a map");
				return;
			}

			// Extract videoBytes
			auto itVideo = args->find(flutter::EncodableValue("videoBytes"));
			if (itVideo == args->end()) {
				result->Error("InvalidArgument", "Missing videoBytes");
				return;
			}
			const auto* videoBytes = std::get_if<std::vector<uint8_t>>(&itVideo->second);
			if (!videoBytes) {
				result->Error("InvalidArgument", "Invalid videoBytes format");
				return;
			}

			// Extract timestamps
			auto itTimestamps = args->find(flutter::EncodableValue("timestamps"));
			if (itTimestamps == args->end()) {
				result->Error("InvalidArgument", "Missing timestamps");
				return;
			}
			const auto* timestampsList = std::get_if<flutter::EncodableList>(&itTimestamps->second);
			if (!timestampsList) {
				result->Error("InvalidArgument", "Invalid timestamps format");
				return;
			}

			std::vector<int64_t> timestamps;
			for (const auto& ts : *timestampsList) {
				if (const auto* timestamp = std::get_if<int>(&ts)) {
					timestamps.push_back(static_cast<int64_t>(*timestamp));
				}
				else {
					result->Error("InvalidArgument", "Timestamps must be integers");
					return;
				}
			}

			// Extract imageWidth
			auto itWidth = args->find(flutter::EncodableValue("imageWidth"));
			if (itWidth == args->end()) {
				result->Error("InvalidArgument", "Missing imageWidth");
				return;
			}
			const auto* imageWidth = std::get_if<double>(&itWidth->second);
			if (!imageWidth) {
				result->Error("InvalidArgument", "Invalid imageWidth format");
				return;
			}

			// Create a temporary file
			wchar_t tempPath[MAX_PATH];
			GetTempPathW(MAX_PATH, tempPath);
			wchar_t tempFile[MAX_PATH];
			GetTempFileNameW(tempPath, L"vid", 0, tempFile);

			HANDLE hFile = CreateFileW(tempFile, GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
			if (hFile == INVALID_HANDLE_VALUE) {
				result->Error("FileError", "Failed to create temp file");
				return;
			}

			DWORD bytesWritten;
			if (!WriteFile(hFile, videoBytes->data(), static_cast<DWORD>(videoBytes->size()), &bytesWritten, nullptr)) {
				CloseHandle(hFile);
				DeleteFileW(tempFile);
				result->Error("FileError", "Failed to write to temp file");
				return;
			}
			CloseHandle(hFile);

			// Initialize Media Foundation
			HRESULT hr = MFStartup(MF_VERSION);
			if (FAILED(hr)) {
				DeleteFileW(tempFile);
				result->Error("MediaError", "Failed to initialize Media Foundation");
				return;
			}

			IMFSourceReader* pSourceReader = nullptr;
			hr = MFCreateSourceReaderFromURL(tempFile, nullptr, &pSourceReader);
			if (FAILED(hr) || !pSourceReader) {
				DeleteFileW(tempFile);
				result->Error("MediaError", "Failed to create source reader");
				return;
			}

			// Retrieve native media type
			IMFMediaType* pNativeType = nullptr;
			hr = pSourceReader->GetNativeMediaType(static_cast<DWORD>(MF_SOURCE_READER_FIRST_VIDEO_STREAM), 0, &pNativeType);
			if (FAILED(hr)) {
				pSourceReader->Release();
				DeleteFileW(tempFile);
				result->Error("MediaError", "Failed to retrieve native media type");
				return;
			}

			GUID nativeSubtype;
			hr = pNativeType->GetGUID(MF_MT_SUBTYPE, &nativeSubtype);
			pNativeType->Release();
			if (FAILED(hr)) {
				pSourceReader->Release();
				DeleteFileW(tempFile);
				result->Error("MediaError", "Failed to get native format");
				return;
			}

			// Set output media type
			IMFMediaType* pMediaTypeOut = nullptr;
			hr = MFCreateMediaType(&pMediaTypeOut);
			if (FAILED(hr)) {
				pSourceReader->Release();
				DeleteFileW(tempFile);
				result->Error("MediaError", "Failed to create media type");
				return;
			}

			hr = pMediaTypeOut->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
			hr |= pMediaTypeOut->SetGUID(MF_MT_SUBTYPE, nativeSubtype);

			if (FAILED(hr)) {
				pMediaTypeOut->Release();
				pSourceReader->Release();
				DeleteFileW(tempFile);
				result->Error("MediaError", "Failed to set media type");
				return;
			}

			hr = pSourceReader->SetCurrentMediaType(static_cast<DWORD>(MF_SOURCE_READER_FIRST_VIDEO_STREAM), nullptr, pMediaTypeOut);
			pMediaTypeOut->Release();
			if (FAILED(hr)) {
				pSourceReader->Release();
				DeleteFileW(tempFile);
				result->Error("MediaError", "Failed to set media type");
				return;
			}

			flutter::EncodableList thumbnails;
			IWICImagingFactory* pWICFactory = nullptr;
			hr = CoCreateInstance(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&pWICFactory));
			if (FAILED(hr)) {
				pSourceReader->Release();
				DeleteFileW(tempFile);
				result->Error("MediaError", "Failed to create WIC factory");
				return;
			}

			for (int64_t timestamp : timestamps) {
				PROPVARIANT var;
				PropVariantInit(&var);
				var.vt = VT_I8;
				var.hVal.QuadPart = timestamp * 10000; // Convert ms to 100-ns units
				hr = pSourceReader->SetCurrentPosition(GUID_NULL, var);
				PropVariantClear(&var);

				if (FAILED(hr)) continue;

				DWORD flags;
				IMFSample* pSample = nullptr;
				hr = pSourceReader->ReadSample(static_cast<DWORD>(MF_SOURCE_READER_FIRST_VIDEO_STREAM), 0, nullptr, &flags, nullptr, &pSample);

				if (SUCCEEDED(hr) && pSample) {
					IMFMediaBuffer* pBuffer = nullptr;
					hr = pSample->ConvertToContiguousBuffer(&pBuffer);
					if (SUCCEEDED(hr)) {
						BYTE* pData = nullptr;
						DWORD cbBuffer;
						hr = pBuffer->Lock(&pData, nullptr, &cbBuffer);
						if (SUCCEEDED(hr)) {
							std::vector<uint8_t> jpegData(pData, pData + cbBuffer);
							thumbnails.push_back(flutter::EncodableValue(jpegData));
							pBuffer->Unlock();
						}
						pBuffer->Release();
					}
					pSample->Release();
				}
			}

			pWICFactory->Release();
			pSourceReader->Release();
			DeleteFileW(tempFile);
			result->Success(thumbnails);
		}
		else {
			result->NotImplemented();
		}
	}

}  // namespace pro_video_editor