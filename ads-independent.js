// Generated by CoffeeScript 1.6.3
(function() {
  (function() {
    'use strict';
    var ad_count, document, init, loadAd, module, refreshables, root, serialize, settings, upon, _ref;
    root = window || global;
    document = root.document;
    Object.extend = function() {
      var argLenSansInitial, args, destination, i, propName, propVal, src, _i, _len, _ref;
      args = Array.prototype.slice.call(arguments);
      argLenSansInitial = args.length - 1;
      _ref = args.reverse();
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        src = _ref[i];
        if (i > argLenSansInitial) {
          src = arguments[i];
          destination = arguments[i + 1];
          for (propVal in src) {
            propName = src[propVal];
            if (propVal.constructor === Object) {
              destination[propName] = propVal || {};
              Object.extend(destination[propName], propVal);
            } else {
              destination[propName] = propVal;
            }
          }
        }
      }
      return destination;
    };
    upon = function(type, selector, func) {
      var del, delegate;
      delegate = function(evt) {
        var el, els, _i, _len;
        if (selector.nodeName || selector === root || selector === document) {
          els = [selector];
        } else {
          els = document.querySelectorAll(selector);
        }
        for (_i = 0, _len = els.length; _i < _len; _i++) {
          el = els[_i];
          if (evt.currentTarget === el) {
            return func.call(evt.target, evt);
          }
        }
      };
      del = selector !== root ? document : root;
      if (del.addEventListener) {
        return del.addEventListener(type, function(e) {
          return delegate(e);
        }, false);
      } else if (del.attachEvent) {
        del.attachEvent('on' + type, function(e) {});
        return delegate(e);
      }
    };
    ad_count = 0;
    refreshables = [];
    settings = {
      srcdoc: '',
      fallback: '',
      pushdown: false,
      refreshable: false,
      dcopt: '',
      height: '',
      is_intersticial: void 0,
      kw: (_ref = document.querySelector('meta[name="keywords"]')) != null ? _ref.getAttribute('content') : void 0,
      publisher: 'ng',
      site_name: '',
      sz: '300x250',
      sizes: void 0,
      tile: '',
      topic: '',
      sbtpc: '',
      slot: '',
      width: '',
      zone: '',
      zone_suffix: ''
    };
    init = function(ads, options) {
      if (ads == null) {
        ads = [];
      }
      if (options == null) {
        options = {};
      }
      ads = Array.prototype.slice.call(ads);
      return ads.forEach(function(el, i, list) {
        var data, opts, parameters, params, path, rand, size;
        data = el.adsData;
        parameters = {};
        path = root.location.pathname.split('/');
        if (!data) {
          opts = Object.extend({}, settings, el.getAttribute('data-ad', options));
          data = {};
          if (opts.sizes) {
            rand = Math.random();
            return size = rand <= opts.sizes[0][1] ? opts.sizes[0][0] : opts.sizes[1][0];
          }
        } else {
          size = opts.sz.split('x');
          if (opts.widht !== '') {
            size[0] = opts.widht;
          }
          if (opts.height !== '') {
            size[1] = opts.height;
          }
          size = size.join('x');
          data.ad_count = ad_count;
          parameters.dcopt = opts.is_intersticial !== void 0 ? opts.is_intersticial : opts.dcopt;
          parameters.kw = opts.kw;
          parameters.publisher = opts.publisher;
          parameters.site_name = opts.site_name !== '' ? opts.site_name : (path[1] && path[1] !== 'channel' ? path[1] : 'ngc');
          parameters.tile = opts.tile === '' ? ad_count : opts.tile;
          if (opts.topic !== '') {
            parameters.topic = opts.topic;
          }
          if (opts.sbtpc !== '') {
            parameters.sbtpc = opts.sbtpc;
          }
          if (opts.slot !== '') {
            parameters.slot = opts.slot;
          }
          parameters.sz = size;
          parameters.zone = "" + (!opts.zone ? (path.length > 3 ? path[2] : 'homepage') : void 0) + opts.zone_suffix;
          data.options = opts;
          data.ad_params = parameters;
          el.adsData(data);
          if (opts.refreshable) {
            refreshables.push(el);
          }
          ad_count += 1;
          upon('stateChange', root, function(e) {
            var timer;
            root.clearTimeout(timer);
            return timer = root.setTimeout(function() {
              return module(refreshables, 500);
            });
          });
          params = Object.extend({}, data != null ? data.ad_params : void 0);
          return loadAd.call(el, params);
        }
      });
    };
    loadAd = function(el, params) {
      var ad, adFrame, ad_base, ad_iframe, ad_img, ad_js, data, err, frame_id, opts, publisher, site_name, tile, unWrapped, zone;
      data = el.adsData;
      opts = data.options;
      data = $this.data(module);
      opts = data.options;
      ad_base = 'http://ad.doubleclick.net/ad';
      ad_img = "" + ad_base + "/";
      ad_iframe = "" + ad_base + "i/";
      ad_js = "" + ad_base + "j/";
      adFrame = document.createElement('iframe');
      unWrapped = document.createElement('script');
      params.ord = Math.floor(1000000 * Math.random());
      publisher = params.publisher;
      delete params.publisher;
      site_name = params.site_name;
      delete params.site_name;
      zone = params.zone;
      delete params.zone;
      frame_id = 'ad_frame' + data.ad_count;
      tile = data.ad_count;
      adFrame.setAttribute('width', '100%');
      adFrame.setAttribute('height', params.sz.split('x')[1]);
      adFrame.setAttribute('allowtransparency', true);
      adFrame.setAttribute('id', frame_id);
      adFrame.setAttribute('name', frame_id);
      adFrame.setAttribute('seamless', true);
      adFrame.setAttribute('frameborder', 0);
      adFrame.setAttribute('src', "" + ad_iframe + publisher + "." + site_name + "/" + zone + ";" + (serialize(params)));
      if (opts.pushdown) {
        unWrapped.src = ad_js + serialize(params);
        ad = unWrapped;
      } else {
        try {
          adFrame.innerHTML = fallback;
        } catch (_error) {
          err = _error;
        }
        ad = adFrame;
      }
      return el.innerHTML = adFrame;
    };
    serialize = function(obj) {
      var key, params, val;
      params = (function() {
        var _results;
        _results = [];
        for (key in obj) {
          val = obj[key];
          _results.push("" + key + "=" + (encodeURI(val)));
        }
        return _results;
      })();
      return params.join(';');
    };
    module = function() {
      return init.call(this, arguments);
    };
    module.init = init;
    module.loadAd = loadAd;
    return module;
  })();

}).call(this);
