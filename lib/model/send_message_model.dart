class SendMessageModel {
  bool? success;
  Message? message;

  SendMessageModel({this.success, this.message});

  SendMessageModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message =
        json['message'] != null ? new Message.fromJson(json['message']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.message != null) {
      data['message'] = this.message!.toJson();
    }
    return data;
  }
}

class Message {
  String? userId;
  String? text;
  bool? isUser;
  Null? image;
  Null? videoUrl;
  Null? multiImageUrl;
  Null? enhancedImageUrl;
  String? timestamp;
  String? sId;
  int? iV;

  Message(
      {this.userId,
      this.text,
      this.isUser,
      this.image,
      this.videoUrl,
      this.multiImageUrl,
      this.enhancedImageUrl,
      this.timestamp,
      this.sId,
      this.iV});

  Message.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    text = json['text'];
    isUser = json['isUser'];
    image = json['image'];
    videoUrl = json['videoUrl'];
    multiImageUrl = json['multiImageUrl'];
    enhancedImageUrl = json['enhancedImageUrl'];
    timestamp = json['timestamp'];
    sId = json['_id'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userId'] = this.userId;
    data['text'] = this.text;
    data['isUser'] = this.isUser;
    data['image'] = this.image;
    data['videoUrl'] = this.videoUrl;
    data['multiImageUrl'] = this.multiImageUrl;
    data['enhancedImageUrl'] = this.enhancedImageUrl;
    data['timestamp'] = this.timestamp;
    data['_id'] = this.sId;
    data['__v'] = this.iV;
    return data;
  }
}
