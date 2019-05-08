part of mqtt_im_client;

typedef void Fun(Result result);

class _FunctionBufferMapItem {
  Fun _fun;
  Timer _timer;

  _FunctionBufferMapItem(this._fun, this._timer);

  Fun get fun => this._fun;
  Timer get timer => this._timer;
}

class _FunctionBufferMap<K> {
  Map<K, _FunctionBufferMapItem> _bufferMap;
  Duration _duration;

  _FunctionBufferMap(this._duration){
    _bufferMap = new Map<K, _FunctionBufferMapItem>();
  }

  void add(K key, Fun fun){
    //set timeout timer
    Timer timer = Timer(_duration, (){
      if(_bufferMap.containsKey(key)) {
        _FunctionBufferMapItem item = _bufferMap[key];
        _bufferMap.remove(key);
        //call fun
        //result failed
        item.fun(new Result(false, error: new Exception("timeout")));
      }
      else mqtt.MqttLogger.log("error: Fail to stop timer");
    });
    //add to send map
    _bufferMap[key] = new _FunctionBufferMapItem(fun, timer);
  }

  void complete(K key, bool succeeded, {Exception error}){
    if(_bufferMap.containsKey(key)){
      _FunctionBufferMapItem item = _bufferMap[key];
      _bufferMap.remove(key);
      //cancel overtime timer
      item.timer.cancel();
      //call fun
      if(succeeded){
        //result succeed
        item.fun(new Result(true));
      }else{
        item.fun(new Result(false, error: error));
      }
    }else mqtt.MqttLogger.log("error: Key no found");
  }
}

class _FileBox {
  String ip;
  int port;
  File file;
  OnUploadProgress onUploadProgress;

  _FileBox(this.ip, this.port, this.file, this.onUploadProgress);
}

abstract class ImHandler<K> implements Handler<Fun, void> {
  mqtt.MqttClient _mqttClient;
  _FunctionBufferMap<K> _functionBufferMap;

  ImHandler(this._mqttClient, Duration duration){
    _functionBufferMap = new _FunctionBufferMap<K>(duration);
  }

  ImHandler _setContent(ImTopic t, {ImMessage m, _FileBox f});
}

class ImSender extends ImHandler<int> {
  ImTopic _imTopic;
  ImMessage _imMessage;
  _FileBox _fileBox;

  ImSender(mqtt.MqttClient mqttClient, int timeout)
      :super(mqttClient, new Duration(seconds: timeout)){
    _listenSendMessage();
  }

  @override
  void handle(Fun t) {
    // TODO: implement handle
    if(_fileBox != null) Http.uploadFile(_fileBox.ip, _fileBox.port,
          _fileBox.file, _fileBox.onUploadProgress).then((url){
            _mqttPublish(t, url: url);
      }, onError: (error){
            t(new Result(false, error: new Exception(error.toString())));
    });
    else _mqttPublish(t);
  }

  @override
  ImHandler _setContent(ImTopic t, {ImMessage m, _FileBox f}) {
    // TODO: implement setContent
    if(m == null){
      throw Exception("ImMessage is null");
    }else{
      this._imTopic = t;
      this._imMessage = m;
      this._fileBox = f;
    }
    return this;
  }

  StreamSubscription<mqtt.MqttPublishMessage> _listenSendMessage() => _mqttClient.published.listen((message){
    //check send message is send succeed
    _functionBufferMap.complete(message.variableHeader.messageIdentifier, true);
  }, onError: (error){
    mqtt.MqttLogger.log("error: $error");
  });

  void _mqttPublish(Fun t, {String url}){
    if(url != null) _imMessage.setSendContent(url);
    //publish message
    int messageId = _mqttClient.publishMessage(_imTopic.toStr(),
        mqtt.MqttQos.atLeastOnce, _buildPayload(_imMessage).payload);
    //add send message to map
    _functionBufferMap.add(messageId, t);
  }

  mqtt.MqttClientPayloadBuilder _buildPayload(ImMessage imMessage){
    mqtt.MqttClientPayloadBuilder builder = new mqtt.MqttClientPayloadBuilder();
    builder.addUTF8String(new JsonCodec().encode(imMessage));
    return builder;
  }
}

class ImAdder extends ImHandler<String> {
  ImTopic _imTopic;

  ImAdder(mqtt.MqttClient mqttClient, int timeout)
      :super(mqttClient, new Duration(seconds: timeout)){
    _listenSubscribeMessage();
  }

  @override
  void handle(Fun t) {
    // TODO: implement handle
    _mqttClient.subscribe(_imTopic.toStr(), mqtt.MqttQos.atLeastOnce);
    //add subscribe message to map
    _functionBufferMap.add(_imTopic.toStr(), t);
  }

  @override
  ImHandler _setContent(ImTopic t, {ImMessage m, _FileBox f}) {
    // TODO: implement setContent
    this._imTopic = t;
    return this;
  }

  void _listenSubscribeMessage(){
    //listen subscribe succeed
    _mqttClient.onSubscribed = (topicStr){
      _functionBufferMap.complete(topicStr, true);
    };
    //listen subscribe failed
    _mqttClient.onUnsubscribed = (topicStr){
      _functionBufferMap.complete(topicStr, false, error: new Exception("sucscribed failed"));
    };
  }
}

class ImDeleter extends ImHandler<String> {
  ImTopic _imTopic;

  ImDeleter(mqtt.MqttClient mqttClient, int timeout)
      :super(mqttClient, new Duration(seconds: timeout)){
    _listenUnsubscribeMessage();
  }

  @override
  void handle(Fun t) {
    // TODO: implement handle
    _mqttClient.unsubscribe(_imTopic.toStr());
    //add unsubscribe message to map
    _functionBufferMap.add(_imTopic.toStr(), t);
  }

  @override
  ImHandler _setContent(ImTopic t, {ImMessage m, _FileBox f}) {
    // TODO: implement setContent
    this._imTopic = t;
    return this;
  }

  void _listenUnsubscribeMessage(){
    //listen unsubscribe succeed
    _mqttClient.onUnsubscribed = (topicStr){
      _functionBufferMap.complete(topicStr, true);
    };
  }
}

class ImHandlerFactory {

  static ImHandler<int> produceImSender(mqtt.MqttClient mqttClient, int timeout)
  => new ImSender(mqttClient, timeout);

  static ImHandler<String> produceImAdder(mqtt.MqttClient mqttClient, int timeout)
  => new ImAdder(mqttClient, timeout);

  static ImHandler<String> produceImDeleter(mqtt.MqttClient mqttClient, int timeout)
  => new ImDeleter(mqttClient, timeout);
}