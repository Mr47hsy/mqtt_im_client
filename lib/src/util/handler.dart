part of mqtt_im_client;

abstract class Handler<T,R> {
  R handle(T t);
}