/**
 * Flash Uploader
 *
 * @author http://yanbingbing.com
 */
(function (window, undefined) {
    var document = window.document;

    function parseJSON(data) {
        try {
            return window.JSON ? window.JSON.parse(data) : (new Function('return ' + data))();
        } catch (e) {
            return null;
        }
    }

    function css(elem, name, value) {
        if (typeof name == 'object') {
            for (var k in name) {
                css(elem, k, name[k]);
            }
            return elem;
        }
        if (!elem || elem.nodeType === 3 || elem.nodeType === 8) {
            return elem;
        }
        if (typeof value === 'number') {
            value += 'px';
        }
        if ((name === 'width' || name === 'height') && parseFloat(value) < 0) {
            value = undefined;
        }
        if (value !== undefined) {
            elem.style[name] = value;
        }
        return elem;
    }

    function extend(target, source) {
        for (var key in source) {
            target[key] = source[key];
        }
        return target;
    }

    var elemCreator = document.createElement('div');

    function toElement(html) {
        elemCreator.innerHTML = html;
        html = elemCreator.firstChild;
        elemCreator.removeChild(html);
        return html;
    }

    function append(elem, value) {
        elem.appendChild(value);
        return elem;
    }

    var R_SPLIT = /[\s|,]+/;

    function each(o, fn) {
        o = o.split(R_SPLIT);
        for (var i = 0, l = o.length, t = o[0]; i < l && fn.call(t, t, i) !== false; t = o[++i]) {
        }
    }

    var flashVersion = (function () {
        try {
            return (window.ActiveXObject
                ? (new window.ActiveXObject('ShockwaveFlash.ShockwaveFlash')).GetVariable('$version')
                : navigator.plugins['Shockwave Flash'].description).match(/\d+/g).join('.') || null;
        } catch (e) {
            return null;
        }
    })();

    function version_test(a, b) {
        if (!a) return false;
        a = a.split('.');
        b = b.split('.');
        a[0] = parseInt(a[0], 10);
        b[0] = parseInt(b[0], 10);
        for (var i = 0, l = b.length; i < l; i++) {
            if (a[i] == undefined || a[i] < b[i]) {
                return false;
            } else if (a[i] > b[i]) {
                return true;
            }
        }
        return true;
    }

    function _genValue(obj, enc) {
        if (obj instanceof Object) {
            var arr = [];
            for (var k in obj) {
                arr.push(k + '=' + _genValue(obj[k], 1));
            }
            obj = arr.join('&');
        }
        return enc ? encodeURIComponent(obj) : obj;
    }

    function _genAttrs(obj) {
        var arr = [];
        for (var k in obj) {
            obj[k] && arr.push([k, '="', _genValue(obj[k]), '"'].join(''));
        }
        return arr.join(' ');
    }

    function _genParams(obj) {
        var arr = [];
        for (var k in obj) {
            arr.push(['<param name="', k, '" value="', _genValue(obj[k]), '" />'].join(''));
        }
        return arr.join('');
    }

    var R_PROTOCOL = /^\w{3,6}:\/\//;

    function absUrl(script) {
        var pathname = location.pathname;
        if (script.substr(0, 1) != '/' && !R_PROTOCOL.test(script)) {
            pathname = pathname.split('/');
            pathname[pathname.length - 1] = script.substr(0, 1) == '?'
                ? (pathname[pathname.length - 1] + script)
                : script;
            script = pathname.join('/');
        }
        return script;
    }

    function callFlash(movie, functionName, argumentArray) {
        try {
            movie.CallFunction('<invoke name="' + functionName + '" returntype="javascript">' + __flash__argumentsToXML(argumentArray || [], 0) + '</invoke>');
        } catch (ex) {
            throw "Call to " + functionName + " failed";
        }
    }

    var TRIGGERS = {
        'before:uploadcomplete': function (uploader, args) {
            if (args) {
                var data = decodeURIComponent(args[0].data);
                args[0].data = data;
                if (uploader.isReturnJson()) {
                    data = parseJSON(data);
                }
                args.unshift(data);
            }
        },
        'after:selectend': function (uploader, args) {
            uploader.isAuto() && uploader.upload();
        }
    }, EVENTS = {}, _debug;

    function addEvent(guid, type, fn) {
        type = type.toLowerCase();
        if (!EVENTS[guid]) {
            EVENTS[guid] = {};
        }
        if (!EVENTS[guid][type]) {
            EVENTS[guid][type] = [];
        }
        EVENTS[guid][type].push(fn);
    }

    function emitEvent(guid, type, args) {
        var uploader = INSTS[guid], fn, listeners;
        if (!uploader) return;
        type = type.toLowerCase();
        fn = TRIGGERS['before:' + type];
        fn && fn(uploader, args);
        _debug && _debug(guid, type, args);
        listeners = EVENTS[guid];
        if (listeners) {
            listeners = listeners[type];
        }
        if (listeners) {
            for (var i = 0; fn = listeners[i++];) {
                fn.apply(uploader, args);
            }
        }
        fn = TRIGGERS['after:' + type];
        fn && fn(uploader, args);
    }

    var SWF_URL = 'uploader.swf', SWF_VERSION = '11.4.0';

    function createFlash(guid, opts) {
        if (!version_test(flashVersion, SWF_VERSION)) {
            throw 'flash version not available';
        }

        var div = document.createElement('div');
        var movie = SWF_URL + (SWF_URL.indexOf('?') > -1 ? '&' : '?') + guid;
        opts.type = 'application/x-shockwave-flash';
        if (window.ActiveXObject) {
            var attrs = {
                classid: 'clsid:D27CDB6E-AE6D-11cf-96B8-444553540000',
                style: 'position:absolute;left:0;top:0;display:block;z-index:1',
                id: guid
            };
            each('width height', function (k) {
                opts[k] && (attrs[k] = opts[k]);
                delete opts[k];
            });
            opts.movie = movie;
            div.innerHTML = [
                '<object ', _genAttrs(attrs), '>',
                _genParams(opts),
                '</object>'
            ].join('');
        } else {
            opts.style = 'position:absolute;left:0;top:0;display:block;z-index:1';
            opts.src = movie;
            opts.id = guid;
            div.innerHTML = '<embed ' + _genAttrs(opts) + ' />';
        }
        return div.firstChild;
    }

    var PULGINS = {};

    function bindPlugin(plugins, uploader) {
        plugins && each(plugins, function (plug) {
            (plug in PULGINS) && PULGINS[plug](uploader);
        });
    }

    var INSTS = {}, EXPANDO = 'expando' + (new Date).getTime();

    function saveUploader(elem, guid, uploader) {
        elem[EXPANDO] = guid;
        INSTS[guid] = uploader;
    }

    var OPTIONS = {
        /*
         fieldName:'Filedata',
         plugin:'progress',
         params:{},
         fileExt:'',
         fileDesc:'',
         multi:true,
         sizeLimit:0,
         queueLengthLimit:0,

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
         jsonType: 0,
         */
        script: '',
        auto: true,
        multi: true,
        plugin : 'progress'
    };
    var Uploader = function (elem, opt) {
        opt = extend(extend({}, OPTIONS), opt || {});
        var _this = this,
            guid = 'UPLOADER' + (new Date()).getTime().toString(16),
            vars = {guid: guid, script: absUrl(opt.script || ''), jsonType: opt.jsonType ? 1 : 0};
        _this.guid = guid;
        _this.auto = opt.auto;
        _this.returnJson = opt.jsonType;
        _this.params = extend({}, opt.params || {});

        each('fileExt fileDesc fieldName multi sizeLimit queueLengthLimit', function (k) {
            opt[k] && (vars[k] = opt[k]);
        });
        each('selectStart selectOne selectEnd uploadStart uploadProgress uploadComplete uploadCancel queueStart queueComplete queueSuccess queueFull queueClear error', function (k) {
            opt[k] && _this.bind(k, opt[k]);
        });
        css(elem, {position: 'relative', overflow: 'hidden', display: 'inline-block'});
        bindPlugin(opt.plugin, _this);
        saveUploader(elem, guid, _this);
        function display() {
            var w = elem.offsetWidth, h = elem.offsetHeight;
            if (!w || !h) {
                setTimeout(display, 1000);
                return;
            }
            append(elem, _this.movie = createFlash(guid, {
                width: w,
                height: h,
                flashvars: vars,
                quality: 'high',
                wmode: 'transparent',
                allowScriptAccess: 'always'
            }));
            display = null;
        }

        display();
    };
    Uploader.prototype = {
        isAuto: function () {
            return this.auto;
        },
        isReturnJson: function () {
            return this.returnJson;
        },
        getParams: function () {
            return this.params;
        },
        getMovie: function () {
            return this.movie;
        },
        bind: function (evt, fn) {
            if (typeof evt == 'object') {
                for (var k in evt) {
                    addEvent(this.guid, k, evt[k]);
                }
            } else {
                addEvent(this.guid, evt, fn);
            }
        },
        upload: function (ID) {
            callFlash(this.movie, 'startUpload', [ID]);
        },
        setParam: function (key, val) {
            this.params[key] = val;
        },
        cancel: function (ID) {
            callFlash(this.movie, 'cancelUpload', [ID]);
        },
        clear: function () {
            callFlash(this.movie, 'clearQueue');
        }
    };
    Uploader.getUploader = function (elem) {
        var guid = elem[EXPANDO];
        return guid ? INSTS[guid] : null;
    };
    Uploader.addPlugin = function (name, plugin) {
        PULGINS[name] = plugin;
    };
    Uploader.trigger = emitEvent;
    Uploader.readParams = function (guid) {
        _debug && _debug(guid, 'readParams', INSTS[guid].getParams());
        return _genValue(INSTS[guid].getParams());
    };
    Uploader.setSWF = function (url, version) {
        SWF_URL = url;
        version && (SWF_VERSION = version);
    };
    Uploader.setVerbose = function () {
        _debug = function () {
            console.info.apply(console, arguments);
        };
    };
    Uploader.testExternalInterface = function (guid) {
        try {
            callFlash(INSTS[guid].getMovie(), 'testExternalInterface');
        } catch (e) {
        }
    };

    // internal plugin: progress
    (function(){
        var box = null, p = null, b = null;
        function initbox() {
            if (!box) {
                box = toElement('<div class="upload-progress">'+
                    '<div class="inner">'+
                        '<div class="percent-bg"></div>'+
                        '<b class="percent-text"></b>'+
                    '</div>'+
                '</div>');
                append(document.body, box);
                p = box.firstChild.firstChild;
                b = box.firstChild.lastChild;
            }
        }
        function progress(upload) {
            initbox();
            var count = 0, percentage = {};
            upload.bind({
                queueStart:function (data) {
                    count = data.fileCount;
                    percentage = {};
                    css(box, 'display', 'block');
                    css(p, 'width', 0);
                    b.innerHTML = '0%';
                },
                uploadProgress:function (data) {
                    percentage[data.ID] = data.percentage;
                    var s = 0;
                    for (var k in percentage) {
                        s += percentage[k];
                    }
                    s = (count ? (s / count).toFixed() : '100') + '%';
                    css(p, 'width', s);
                    b.innerHTML = s;
                },
                error:function (data) {
                    if (data.ID) {
                        percentage[data.ID] = 100;
                    }
                },
                uploadCancel:function (data) {
                    delete percentage[data.ID];
                    count-=1;
                },
                queueComplete:function (data) {
                    css(p, 'width', '100%');
                    b.innerHTML = '100%';
                    setTimeout(function(){
                        css(box, 'display', 'none');
                    }, 1000);
                }
            });
        }
        Uploader.addPlugin('progress', progress);
    })();

    if (typeof define === 'function') {
        define(function () {
            return Uploader;
        });
    }
    if (!window.Uploader) {
        window.Uploader = Uploader;
    }

})(window);
