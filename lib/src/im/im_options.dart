part of mqtt_im_client;

class ImOptions {
  int _keepAlive;
  int _connectTimeout;
  int _reconnectInterval;
  int _sendTimeout;
  String _username;
  String _password;
  String _fileServerIp;
  int _fileServerPort;

  ImOptions setKeepAlive(int keepAlive){
    this._keepAlive = keepAlive;
    return this;
  }

  ImOptions setConnectTimeout(int connectTimeout){
    this._connectTimeout = connectTimeout;
    return this;
  }

  ImOptions setReconnectInterval(int reconnectInterval){
    this._reconnectInterval = reconnectInterval;
    return this;
  }

  ImOptions setSendTimeout(int sendTimeout){
    this._sendTimeout = sendTimeout;
    return this;
  }

  ImOptions setAuth(String username, String password){
    this._username = username;
    this._password = password;
    return this;
  }

  ImOptions setFileServer(String ip, int port){
    this._fileServerIp = ip;
    this._fileServerPort = port;
    return this;
  }

  int get keepAlive => this._keepAlive;
  int get connectTimeout => this._connectTimeout;
  int get reconnectInterval => this._reconnectInterval;
  int get sendTimeout => this._sendTimeout;
  String get username => this._username;
  String get password => this._password;
  String get fileServerIp => this._fileServerIp;
  int get fileServerPort => this._fileServerPort;
}