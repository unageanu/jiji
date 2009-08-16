/**
 * UUID.js
 *
 * Generates RFC-compliant UUIDs (version 1 or 4).
 * @version 2.0 2008-10-04
 * @see http://www.ietf.org/rfc/rfc4122.txt
 * @license http://liosk.net/-/license/mit The MIT License
 * @copyright Copyright (c) 2008 LiosK (http://liosk.net/)
 */

if (window.UUID == null) {
    window.UUID = {};
}

/*
 * Generator state, used when generating version 1.
 * @access private
 * @var object
 */
window.UUID._state = null;

/**
 * Generates UUID.
 * @access public
 * @param object options
 * @return string
 */
window.UUID.generate = function(options) {
    var rand = this._rand, hex = this._intToPaddedHex;
    if (options && (options.version == 1)) {
        // version 1
        var timestamp = new Date() - Date.UTC(1582, 9, 15);

        if (this._state == null) {
            // initialize state
            this._state = {
                timestamp: timestamp,
                sequence: rand(16384), //16384 = 2^14
                node: hex(rand(256) | 1, 2) + hex(rand(1099511627776), 10) // 1099511627776 = 2^40
            };
        } else {
            // update state
            if (timestamp <= this._state.timestamp) {
                this._state.sequence++;
            } else {
                this._state.timestamp = timestamp;
            }
        }

        var ts  = hex(timestamp * 10000, 15); // overflowing though it's no problem
        var seq = 32768 | (16383 & this._state.sequence); // make initial 2 bits '10'

        return [
            ts.substr(7),
            ts.substr(3, 4),
            '1' + ts.substr(0, 3),
            hex(seq, 4),
            this._state.node
        ].join('-');
    } else {
        // version 4
        return [
            hex(rand(4294967296), 8),                   // 4294967296      = 2^32
            hex(rand(65536), 4),                        // 65536           = 2^16
            '4' + hex(rand(4096), 3),                   // version 4; 4096 = 2^12
            hex(8 | rand(4), 1) + hex(rand(4096), 3),   // variant
            hex(rand(281474976710656), 12)              // 281474976710656 = 2^48
        ].join('-');
    }
};

/**
 * Returns unsigned random integer ranging from zero to max.
 * @access protected
 * @param int max
 * @return int
 * @todo The randomness should be improved (see http://www.ietf.org/rfc/rfc1750.txt).
 */
window.UUID._rand = function(max) {
    var B32 = 4294967296; // 2^32
    if (max <= B32) {
        return Math.floor(Math.random() * max);
    } else {
        var d0 = Math.floor(Math.random() * B32);
        var d1 = Math.floor(Math.random() * Math.floor(max / B32));
        return d0 + d1 * B32;
    }
};

/**
 * Convert integer to zero-padded hex string.
 * @access protected
 * @param int n
 * @param int length
 * @return string
 */
window.UUID._intToPaddedHex = function(n, length) {
    var hex = n.toString(16);
    while (hex.length < length) {
        hex = '0' + hex;
    }
    return hex;
};
