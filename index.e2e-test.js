const request = require('request');
require('dotenv').config();

const url = process.env.DEPLOYED_URL;

describe('request url', () => {
    it('without tz', (done) => {
        request(url, (error, response, data) => {
            if (error) {
                fail(error);
            } else {
                console.log(data);
                const resData = JSON.parse(data);
                expect(resData.statusCode).toBe(200);
                expect(resData.message).toContain('Asia/Shanghai');
            }
            done();
        });
    });

    it('with tz', (done) => {
        request(`${url}?tz=America/New_York`, (error, response, data) => {
            if (error) {
                fail(error);
            } else {
                console.log(data);
                const resData = JSON.parse(data);
                expect(resData.statusCode).toBe(200);
                expect(resData.message).toContain('America/New_York');
            }
            done();
        });
    })

    it('with wrong tz', (done) => {
        request(`${url}?tz=aaa`, (error, response, data) => {
            if (error) {
                fail(error);
            } else {
                const resData = JSON.parse(data);
                expect(resData.statusCode).toBe(400);
                expect(resData.message).toBe('Unknown timezone aaa.');

                const expected = ['America/New_York', 'Asia/Shanghai', 'Africa/Abidjan'];
                expect(resData.timezones).toEqual(expect.arrayContaining(expected));
            }
            done();
        });
    })
});