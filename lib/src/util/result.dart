part of mqtt_im_client;

class Result {
  //判断结果是否成功
  bool _succeed;
  Exception _error;

  Result(bool succeed, {Exception error}){
    this._succeed = succeed;
    if(error != null){
      _error = error;
    }
  }

  bool get succeed => this._succeed;

  bool get failed => (!this._succeed);

  Exception get cause => this._error;
}