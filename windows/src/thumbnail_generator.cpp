#include "thumbnail_generator.h"

#include <windows.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <propvarutil.h>
#include <wincodec.h>
#include <shlwapi.h>
#include <combaseapi.h>
#include <flutter/standard_method_codec.h>
#include <string>
#include <vector>
#include <algorithm>

#pragma comment(lib, "mfplat.lib")
#pragma comment(lib, "mfreadwrite.lib")
#pragma comment(lib, "mfuuid.lib")
#pragma comment(lib, "shlwapi.lib")

namespace pro_video_editor {

void HandleGenerateThumbnails(
    const flutter::EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

  // Extract videoBytes
  auto itVideo = args.find(flutter::EncodableValue("videoBytes"));
  if (itVideo == args.end()) {
    result->Error("InvalidArgument", "Missing videoBytes");
    return;
  }
  const auto* videoBytes = std::get_if<std::vector<uint8_t>>(&itVideo->second);
  if (!videoBytes) {
    result->Error("InvalidArgument", "Invalid videoBytes format");
    return;
  }

  // Extract timestamps
  auto itTimestamps = args.find(flutter::EncodableValue("timestamps"));
  if (itTimestamps == args.end()) {
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
    } else {
      result->Error("InvalidArgument", "Timestamps must be integers");
      return;
    }
  }

  // Extract imageWidth
  auto itWidth = args.find(flutter::EncodableValue("imageWidth"));
  if (itWidth == args.end()) {
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
    var.hVal.QuadPart = timestamp * 10000;
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

}  // namespace pro_video_editor