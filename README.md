FlashUploader
=============

`Flash Uploader`，swf文件在`Flash Builder 4.6`下使用`Flex 4.6.0 SDK`编译，`Adobe Flash Player`版本最低限制`11.1.0`，兼容各种浏览器。

## 使用 Usage

```
new Uploader(document.getElementById("buttonid") [, {
    script: '',
    multi: true,
    auto: true,
	fieldName:'Filedata',
    plugin:'progress',
    params:{},
    fileExt:'jpg;jpeg;gif;bmp;png|flv;mov;rmvb;mp4',
    fileDesc:'图片|视频',
    sizeLimit:0,
    queueLengthLimit:0,
	jsonType: 0,
	selectStart:function(){},
    selectOne:function(){},
    selectEnd:function(){},
    uploadStart:function(){},
    uploadProgress:function(){},
    uploadCompelte:function(){},
    uploadCancel:function(){},
    queueStart:function(){},
    queueComplete:function(){},
    queueSuccess:function(){},
    queueClear:function(){},
    queueFull:function(){},
    error:function(){},
}]);
```

## 参数 Options

 Option          | Type     | Default    | Description
-----------------|----------|------------|-------------
script           | string   | ''         | 后端响应、处理脚本地址，*"uploader/upload.php?app=apc=aa&a=bb"*
fieldName        | string   | 'Filedata' | 上传文件的字段
multi            | boolean  | true       | 是否可以多个同时选择、上传
auto             | boolean  | true       | 是否选择完成后自动上传
fileExt          | string   | '\*.\*'    | 允许上传文件类型，*"\*.jpg;\*.jpeg;\*.gif;\*.bmp;\*.png|\*.flv;\*.mov;\*.rmvb;\*.mp4"*
fileDesc         | string   | ''         | 允许上传文件类型描述，*"图片|视频"*
params           | object   | null       | 需要同步提交的数据，*{key1: val1, key2: val2}*，可通过`<Uploader>.setParam(key, val)`动态设置
sizeLimit        | uint     | 0 (无限制)  | 单个文件大小限制，单位B，*5M = 5 * 1024 * 1024*
queueLengthLimit | uint     | 0 (无限制)  | 单次最大队列
plugin           | string   | 'progress' | 使用插件，以逗号分隔，插件通过`Uploader.addPlugin(name, func)`添加
jsonType         | boolean  | false      | 是否返回的数据是JSON

## 事件 Events

Event          | Arguments | Description
---------------|-----------|-------------
selectStart    | void      | 开始选择并填充上传队列
selectOne      | {ID:String, file:Object} | 选中一个文件
selectEnd      | {fileCount:uint, allBytesTotal:float} | 选择结束
queueFull      | queueLengthLimit:uint | 文件队列已满
queueStart     | {fileCount:uint, allBytesTotal:float} | 队列开始上传
uploadStart    | {ID:String, file:Object} | 一个文件开始调用上传
uploadProgress | {ID:String, file:Object, speed:float, percentage:float, bytesLoaded:float, allBytesLoaded:float}     | 上传进程
uploadComplete | [json, ]{ID:String, file:Object, data:String, fileCount:uint} | 一个文件上传完成，当jsonType为true时，会多一个参数json，获取自JSON.parse(第二个参数字段data)
queueComplete  | {successCount:uint, errorCount:uint, allBytesLoaded:float} | 队列上传完成
queueSuccess   | void      | 队列中文件全部上传成功
uploadCancel   | {ID:String, file:Object} | 退出上传并退出队列
queueClear     | void      | 队列被清空
error          | {ID:String, file:Object, type:String, info:String} | 发生错误

> 其中`file:Object`内容为 {id:String(同ID), name:String(文件名), size:uint(文件大小)}

## 实例方法 Instance Methods

Method       | return     | Arguments | Description
-------------|------------|-----------|-------------
setParam     | void       | key:String, val:* | 添加POST数据，文件开始上传时会合并到协议数据中
bind         | void       | event:String, fn:Function | 绑定事件
upload       | void       | ID:String = null | 开始上传
cancel       | void       | ID:String | 退出单个上传
clear        | void       | void      | 清空队列
getMovie     | DOMElement | void      | 获取swf的DOM节点
getParams    | Object     | void       | 获取所设置的参数
isAuto       | boolean    | void      | 是否开启了自动上传
isReturnJson | boolean    | void      | 是否开启返回json

## 静态方法 Static Methods

Method      | return     | Arguments | Description
------------|------------|-----------|-------------
getUploader | \<Uploader\> | elem:DOMElement | 从DOM节点中获取Uploader实例
addPlugin   | void       | name:String, func:Function | 添加插件
setSWFUrl   | void       | url:String | 设置swf的url
setVerbose  | void       | void      | 开启啰嗦模式，在firebug中输出调试信息



