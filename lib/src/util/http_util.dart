part of mqtt_im_client;

typedef void OnUploadProgress(int sent, int total);

abstract class Http {
  
  static Future<String> uploadFile(String ip, int port,File file,
      OnUploadProgress onUploadProgress) async {
    http.Dio dio = new http.Dio(new http.BaseOptions(baseUrl: "http://$ip:$port",
        connectTimeout: 5000, receiveTimeout: 3000));

    FileStat stat = await file.stat();

    http.Response response = await dio.post(
        "/upload",
        data: http.FormData.from({
          "file": http.UploadFileInfo(
              file, pa.basename(file.path), contentType: ContentType.binary)
        }),
        options: http.Options(
            headers: {
              HttpHeaders.contentLengthHeader: stat.size,
            }
        ),
        onSendProgress: onUploadProgress);

    List urls = response.data as List;
    if(urls.length == 1){
      return urls.first;
    }else{
      throw new Exception("response has too many url");
    }
  }
} 