const moment = require('moment-timezone');

module.exports.handler = function(req, resp, context) {
    let tz = "Asia/Shanghai";

    console.log(`clientIP: ${req.clientIP}`);
    console.log(`requestURI: ${req.url}`);

    resp.setHeader('content-type', 'application/json');

    if(req.queries && req.queries.tz) {
        tz = req.queries.tz;

        if(!moment.tz.names().includes(tz)) {
            console.error(`Unknown timezone ${tz}`);

            resp.send(JSON.stringify({
                statusCode: '400',
                message: `Unknown timezone ${tz}.`,
                timezones: moment.tz.names()
            }, null, '    '));
            return;
        }

        console.log(`timezone: ${tz}`);
    }

    resp.send(JSON.stringify({
        statusCode: '200',
        message: `The time in ${tz} is: ${moment.tz(tz).format()}`
    }, null, '    '));
}