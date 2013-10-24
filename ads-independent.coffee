do () ->
    #
    # Parameters are obtained from a "data-params" attribute on the ad container. All parameters that are required for
    # functionality have defaults so a "data-params" attribute is not required for the script to function. The "p" object
    # defines all parameter values that are useful and as such can be used as a reference for possible "data-params" vaules.
    #
    # USE:
    #  <div class="advertisement" data-ad='{"site_name": "ngc", "zone": "American Weed", "width": "300", "height": "600" }>
    #  </div>
    #
    # ads provides some syntactic sugar useful if one is unfamiliar with DART ad calls. The data-options attribute can take standard DART parameters and it can also take a more
    #      verbose syntax. In cases where both the standard DART parameter and a corresponding verbose syntax exist, the verbose option will win.

    'use strict'

    root = window or global
    document = root.document

    Object.extend = () ->
        # we're looping over a reversed copy of arguments
        # in order to merge in properly. We still need to
        # do a range check to NOT loop over the first
        # argument as it is the target.
        args = Array.prototype.slice.call arguments
        argLenSansInitial = args.length - 1
        for src, i in args.reverse()
            if i > argLenSansInitial
                src = arguments[i]
                destination = arguments[i+1]

                for propVal, propName of src
                    if propVal.constructor is Object
                        destination[propName] = propVal or {}
                        Object.extend destination[propName], propVal
                    else
                        destination[propName] = propVal
        destination

    upon = (type, selector, func) ->
        delegate = (evt) ->
            if selector.nodeName or selector is root or selector is document
                els = [selector] 
            else 
                els = document.querySelectorAll selector
            return func.call(evt.target, evt) for el in els when evt.currentTarget is el 

        del = if selector isnt root then document else root
        if del.addEventListener
            del.addEventListener type, (e) -> 
                delegate(e)
            , false
        else if del.attachEvent
            del.attachEvent 'on' + type, (e) -> 
            delegate(e)



    # module = 'ads'
    ad_count = 0
    refreshables = []
    settings = 
        srcdoc: ''
        fallback: ''
        
        pushdown : false
        refreshable: false

        # DoubleClick parameters
        dcopt : '' #designates ad as an intersticial. Gets overwritten by is_intersticial if it is set.
        height : '' # In pixles
        is_intersticial: undefined # boolean. Overwrites dcopt parameter if set
        kw: document.querySelector('meta[name="keywords"]')?.getAttribute('content'), #key words. Defaults to keywords from pages' meta tag
        publisher: 'ng' # DoubleClick publisher identifier
        site_name : '' # Channel level categorization at NGS
        sz : '300x250' # Gets overwritten if height and/or width is set
        sizes: undefined
        tile: ''  # defualts to index of ad element in collection
        topic: '' # horizontal taging accross verticals
        sbtpc: '' # sub topics
        slot: ''  # A named identifier for a given ad location
        width: '' # In pixles
        zone : '' # Ad Zone. Effectively the subsection
        zone_suffix: '' #NGS appends an identifier to zone for duplicate ad sizes in same zone

    # Methods
    init = (ads = [], options = {}) ->
        ads = Array.prototype.slice.call ads
        ads.forEach (el, i, list) ->
            data = el.adsData
            parameters = {}
            path = root.location.pathname.split '/'

            if not data
                opts = Object.extend {}, settings, el.getAttribute 'data-ad', options

                data = {}

                #setup
                #logic for sizes
                if opts.sizes
                    rand = Math.random()
                    size = if rand <= opts.sizes[0][1] then opts.sizes[0][0] else opts.sizes[1][0]
            else
                size = opts.sz.split 'x'
                size[0] = opts.widht if opts.widht isnt ''
                size[1] = opts.height if opts.height isnt ''
                size = size.join 'x'

                data.ad_count = ad_count

                #build double click parameters from options. Only build what is going to be used.
                parameters.dcopt        = if opts.is_intersticial isnt undefined then opts.is_intersticial else opts.dcopt
                #parameters.dcopt       = if not opts.dcopt and ad_count is 0 then 'ist' else ''
                parameters.kw           = opts.kw
                parameters.publisher    = opts.publisher
                parameters.site_name    = if opts.site_name isnt '' then opts.site_name else (if path[1] and path[1] isnt 'channel' then path[1] else 'ngc') #defaults to whatever the "bookend" is or 'ngc'
                parameters.tile         = if opts.tile is '' then ad_count else opts.tile
                parameters.topic        = opts.topic if opts.topic isnt ''
                parameters.sbtpc        = opts.sbtpc if opts.sbtpc isnt ''
                parameters.slot         = opts.slot if opts.slot isnt ''
                parameters.sz           = size
                parameters.zone         = "#{ (if path.length > 3 then path[2] else 'homepage') if not opts.zone }#{ opts.zone_suffix }"

                data.options    = opts
                data.ad_params  = parameters

                el.adsData data

                refreshables.push el if opts.refreshable

                ad_count += 1

                #events
                upon 'stateChange', root, (e) ->
                    root.clearTimeout timer
                    timer = root.setTimeout -> module refreshables
                    , 500

                params = Object.extend {}, data?.ad_params
                loadAd.call el, params

    loadAd = (el, params) ->
        data = el.adsData
        opts = data.options
        
        # URI Builder
        data    = $this.data module
        opts    = data.options

        # URI builder
        ad_base     = 'http://ad.doubleclick.net/ad'
        ad_img      = "#{ ad_base }/"
        ad_iframe   = "#{ ad_base }i/"
        ad_js       = "#{ ad_base }j/"
        
        # doc frags
        adFrame     = document.createElement 'iframe'
        unWrapped   = document.createElement 'script'

        # Add generated items to be serialized
        params.ord = Math.floor 1000000 * Math.random() #used for cache-busting

        # Store and remove items that shouldn't be serialized
        publisher = params.publisher
        delete params.publisher
        
        site_name = params.site_name
        delete params.site_name

        zone = params.zone
        delete params.zone
        

        frame_id = 'ad_frame' + data.ad_count
        tile     = data.ad_count #used to specify the order of an ad slot on a webpage

        adFrame.setAttribute 'width', '100%'
        adFrame.setAttribute 'height', params.sz.split('x')[1]
        adFrame.setAttribute 'allowtransparency', true
        #adFrame.setAttribute 'sandbox', 'allow-scripts'
        adFrame.setAttribute 'id', frame_id
        adFrame.setAttribute 'name', frame_id
        adFrame.setAttribute 'seamless', true
        adFrame.setAttribute 'frameborder', 0
        adFrame.setAttribute 'src', "#{ ad_iframe }#{ publisher }.#{ site_name }/#{ zone };#{ serialize params }"

        if opts.pushdown
            unWrapped.src = ad_js + serialize params
            ad = unWrapped
        else
            try
                adFrame.innerHTML = fallback
            catch err
            ad = adFrame

        el.innerHTML = adFrame

    serialize = (obj) ->
        params = for key, val of obj
            "#{key}=#{encodeURI val}"

        return params.join ';'

    module = () ->
        init.call this, arguments

    module.init = init 
    module.loadAd = loadAd

    return module
