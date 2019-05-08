part of mqtt_im_client;

typedef void DisconnectHandle();
typedef void ConnectedHandle(ImClient client);
typedef void ReceivedHandle(ImMessage imMessage);
typedef void SendHandle(Result result);
typedef void AddHandle(Result result);
typedef void DeleteHandle(Result result);

class ImClient {
  ImOptions options;
  mqtt.MqttClient _mqttClient;
  DisconnectHandle _disconnectHandle;
  ReceivedHandle _receivedHandle;
  ConnectedHandle _connectedHandle;
  Timer _reconnectTimer;
  ImHandler<int> _sender;
  ImHandler<String> _adder;
  ImHandler<String> _deleter;

  ImClient(String brokerIp, int port, String clientId, ImOptions options){
    _mqttClient = mqtt.MqttClient.withPort(brokerIp, clientId, port);
    this.options = options;
    _mqttClient.keepAlivePeriod = this.options.keepAlive;
    _mqttClient.setProtocolV311();
    //init Connect Options
    _mqttClient.connectionMessage = new mqtt.MqttConnectMessage()
        .withClientIdentifier(clientId)
        .keepAliveFor(this.options.keepAlive)
        .authenticateAs(this.options.username, this.options.password)
        .startClean();
    //init Disconnect Handle
    _mqttClient.onDisconnected = (){
      mqtt.MqttLogger.log("Has been disconnected.Calling DisconnectHandle");
      if(_disconnectHandle != null){
        _disconnectHandle();
      }
      mqtt.MqttLogger.log("Init reconnect timer");
      _reconnectTimer = Timer(new Duration(seconds: this.options.reconnectInterval), (){
        mqtt.MqttLogger.log(">>Now try to reconnect......");
        _mqttConnect(this.options.connectTimeout);
      });
    };
  }
  
  void connect(){
    if(_reconnectTimer != null){
      _reconnectTimer.cancel();
      _reconnectTimer = null;
    }
    _mqttConnect(this.options.connectTimeout);
  }

  ImHandler sendRichText(String targetId, String richText){
    if(_mqttClient.connectionStatus.state == mqtt.MqttConnectionState.connected){
      return _sendRichText(new ImUserTopic(targetId), richText);
    }else{
      throw Exception("Client Disconnect");
    }
  }

  ImHandler sendFile(String targetId, File file, OnUploadProgress onUploadProgress){
    if(_mqttClient.connectionStatus.state == mqtt.MqttConnectionState.connected){
      return _sendFile(new ImUserTopic(targetId), file, onUploadProgress);
    }else{
      throw Exception("Client Disconnect");
    }
  }

  ImHandler add(String targetId){
    if(_mqttClient.connectionStatus.state == mqtt.MqttConnectionState.connected)
      return _adder._setContent(new ImInfoTopic(targetId));
    else throw new Exception("Client Disconnect");
  }

  ImHandler delete(String targetId){
    if(_mqttClient.connectionStatus.state == mqtt.MqttConnectionState.connected)
      return _deleter._setContent(new ImInfoTopic(targetId));
    else throw new Exception("Client Disconnect");
  }

  //open log
  static log({bool on}){
    mqtt.MqttLogger.loggingOn = false;
    if (on) {
      mqtt.MqttLogger.loggingOn = true;
    }
  }

  ImClient disconnectHandle(DisconnectHandle h){
    this._disconnectHandle = h;
    return this;
  }

  ImClient receivedHandle(ReceivedHandle h){
    this._receivedHandle = h;
    return this;
  }

  ImClient connectedHandle(ConnectedHandle h){
    this._connectedHandle = h;
    return this;
  }

  _listenMessage() => _mqttClient.updates.listen((messages){
    mqtt.MqttLogger.log("Received Messages. Calling ReceivedHandle");
    if(_receivedHandle == null){
      return;
    }
    messages.forEach((message){
      _receivedHandle(ImMessage.fromJson(new mqtt.MqttEncoding()
          .decode((message.payload as mqtt.MqttPublishMessage).payload.message)));
    });
  });

  _getOfflineMessage() => _sendRichText(new ImSystemTopic("api"), "getOfflineMessage")
      .handle((result){
    if(result.succeed)mqtt.MqttLogger.log("Get offline message succeed");
    else mqtt.MqttLogger.log("error: ${result.cause}");
  });

  _mqttConnect(int timeOut) {
    _mqttClient.connect(new Duration(seconds: timeOut)).then((status){
      if(status.state == mqtt.MqttConnectionState.connected){
        mqtt.MqttLogger.log("Connected Succeed. Init client listen");
        _sender = ImHandlerFactory.produceImSender(_mqttClient, this.options.sendTimeout);
        _adder = ImHandlerFactory.produceImAdder(_mqttClient, this.options.sendTimeout);
        _deleter = ImHandlerFactory.produceImDeleter(_mqttClient, this.options.sendTimeout);
        _listenMessage();
        mqtt.MqttLogger.log("Init Succeed. Calling ConnectedHandle");
        if(_connectedHandle != null){
          _connectedHandle(this);
        }
        mqtt.MqttLogger.log(">>>Now get offline messages......");
        _getOfflineMessage();
      }
    }, onError: (error){
      mqtt.MqttLogger.log("error: $error");
      mqtt.MqttLogger.log(">>disconnting......");
      _mqttClient.disconnect();
    });
  }

  ImHandler _sendRichText(ImTopic imTopic, String richText){
    ImMessage imMessage = new ImRichTextMessage()
        .setOriginTopic(imTopic)
        .setSendId(this._mqttClient.clientIdentifier)
        .setSendContent(richText)
        .setSendTime(new DateTime.now().millisecondsSinceEpoch);
    mqtt.MqttLogger.log(">>Send RichText Message......");
    return _sender._setContent(imTopic, m: imMessage, f: null);
  }

  ImHandler _sendFile(ImTopic imTopic, File file, OnUploadProgress onUploadProgress){
    ImMessage imMessage = new ImRichTextMessage()
        .setOriginTopic(imTopic)
        .setSendId(this._mqttClient.clientIdentifier)
        .setSendContent(null)
        .setSendTime(new DateTime.now().millisecondsSinceEpoch);
    mqtt.MqttLogger.log(">>Send File Message......");
    return _sender._setContent(imTopic,
        m: imMessage,
        f: new _FileBox(this.options._fileServerIp, this.options._fileServerPort,
            file, onUploadProgress));
  }
}
