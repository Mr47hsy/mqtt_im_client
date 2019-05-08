part of mqtt_im_client;

abstract class BrokerHttp {
  http.Dio _dio;

//  BrokerHttp(String brokerIp, int port,
//      String username, String password){
//    _dio = new http.Dio(new http.Options(baseUrl: "http://$brokerIp:$port",
//        connectTimeout: 5000, receiveTimeout: 3000,
//        headers: {"Authorization" : "Basic ${base64Encode(utf8.encode("$username:$password"))}"}));
//  }
}

class UserStateBrokerHttp extends BrokerHttp implements Handler<String, Future<bool>>{
//  UserStateBrokerHttp(String brokerIp, int port,
//      String username, String password) : super(brokerIp, port, username, password);

  @override
  Future<bool> handle(String t) async {
    // TODO: implement handle
    http.Response response = await _dio.get("/api/v2/clients/$t");
    //检查返回数据，确认用户是否在线
    if(((response.data["result"] as Map<String, dynamic>)["objects"] as List).isNotEmpty){
      return true;
    }else{
      return false;
    }
  }
}

class SelectRetweeterBrokerHttp extends BrokerHttp implements Handler<void, Future<String>> {
//  SelectRetweeterBrokerHttp(String brokerIp, int port,
//      String username, String password) : super(brokerIp, port, username, password);

  @override
  Future<String> handle(void t) async {
    // TODO: implement handle
    return "Retweeter0";
  }
}

//class BrokerHttpHandlerFactory {
//  static Handler<String, Future<bool>> produceUserStateBrokerHttp(String brokerIp, int port,
//      String username, String password) => new UserStateBrokerHttp(brokerIp, port, username, password);
//
//  static Handler<void, Future<String>> produceSelecetRetweeterBrokerHttp(String brokerIp, int port,
//      String username, String password) => new SelectRetweeterBrokerHttp(brokerIp, port, username, password);
//}