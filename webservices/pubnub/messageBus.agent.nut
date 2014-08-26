// Library for Device-To-Device communication with PubNub
// Requires PubNub class (https://github.com/electricimp/reference/tree/master/webservices/pubnub)
class MessageBus {
    _wildcard = "\x00\x00\x00\x00";
    
    _pubNub = null;
    _channel = null;
    
    _ignoreSelf = null;
    
    _callbacks = null;
    
    /************************************************************
     * params:
     *  pubNub - an initialized PubNub object
     *  ignoreSelf - true if you want to ignore messages generated
     *                  by your uuid
     *               false if you want to trigger callbacks from
     *                  messages generated by your uuid
     *  channel (optional) - the name of the feed to track
     ************************************************************/
    constructor(pubNub, ignoreSelf = true, channel = "messageBus") {
        _pubNub = pubNub;
        _ignoreSelf = ignoreSelf;
        _channel = channel;
        _callbacks = {};
        
        _pubNub.subscribe([channel], _onEvent.bindenv(this));
    }

    /************************************************************
     * function: on
     * desc: adds a callback function for a particular event
     * params:
     *  event - the name of the event to trigger on
     *  cb - a callback function with 1 parameter (data)
     ************************************************************/
    function on(event, cb) {
        this.onDevice(null, event, cb);
    }
    
    /************************************************************
     * function: onDevice
     * desc: adds a callback function for a particular event
     *       generated by a particular device
     * params:
     *  uuid - the uuid of the device to trigger on
     *  event - the name of the event to trigger on
     *  cb - a callback function with 1 parameter (data)
     ************************************************************/
    function onDevice(uuid, event, cb) {
        // create slot for event
        if(!(event in _callbacks)) {
            _callbacks[event] <- {};
        }
        
        if(uuid == null) uuid = _wildcard;
        
        // create slot for uuid
        if(!(uuid in _callbacks[event])) {
            _callbacks[event][uuid] <- null;
        }
        
        // populate slot
        _callbacks[event][uuid] = cb;
    }
    
    /************************************************************
     * function: send
     * desc: sends a message to the public feed
     * params:
     *  event - the name of the event
     *  data - the events data
     ************************************************************/
    function send(event, data) {
        local d = { uuid = _pubNub._uuid, event = event, data = http.jsonencode(data) };
        _pubNub.publish(_channel, d, function(err, result) { 
            if (err != null) {
                server.log("Error Publishing Data - " + err);
            }
        }.bindenv(this));
    }
    
    /*************** PRIVATE FUNCTIONS (DO NOT CALL) ***************/
    function _onEvent(err, result, tt) {
        // check for errors
        if (err) {
            server.log("Error - " + err);
            return;
        }

        // make sure there was a message, and grab it
        if (!(result != null && _channel in result)) return;
        local message = result[_channel];
        
        // make sure the message looks correct:
        if (!("event" in message && "uuid" in message && "data" in message)) return;

        // Make sure that we didn't generate the message AND have ignoreSelf set
        if (message.uuid == _pubNub._uuid && _ignoreSelf == true) return;
        
        // look for a device + event specific match
        if (message.event in _callbacks) {
            if (message.uuid in _callbacks[message.event]) {
                _callbacks[message.event][message.uuid](message.data);
                return;
            } else if (_wildcard in _callbacks[message.event]) {
                _callbacks[message.event][_wildcard](message.data);
                return;
            }
        }
    }
}

