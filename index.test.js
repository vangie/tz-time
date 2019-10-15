jest.mock('moment-timezone');

const { tz } = require('moment-timezone');
const { handler } = require('./index');

const EXPECTED_DATE = '2018-10-01 00:00:00';
const TIMEZONE = 'America/New_York';

describe('when call handle', () => {
    it('Should return the expected date if the provied timezone exists', () => {
        const mockReq = {
            queries: {
                tz: TIMEZONE
            }
        }
        const mockResp = {
            setHeader: jest.fn(),
            send: jest.fn()
        }

        tz.names = () => [TIMEZONE];
        tz.mockImplementation(() => {
            return {
                format: () => EXPECTED_DATE 
            }
        })

        handler(mockReq, mockResp, null);

        expect(mockResp.setHeader.mock.calls.length).toBe(1);
        expect(mockResp.setHeader.mock.calls[0][0]).toBe('content-type');
        expect(mockResp.setHeader.mock.calls[0][1]).toBe('application/json');

        expect(mockResp.send.mock.calls.length).toBe(1);
        expect(mockResp.send.mock.calls[0][0]).toBe(JSON.stringify({
            statusCode: '200',
            message: `The time in ${TIMEZONE} is: ${EXPECTED_DATE}`
        }, null, '    '));

    });

    it('Should return the date for the default timezone if none has been specified', () => {
        const mockReq = {
            queries: {}
        }
        const mockResp = {
            setHeader: jest.fn(),
            send: jest.fn()
        }
        tz.names = () => { return [TIMEZONE]; };

        tz.mockImplementation(() => {
          return {
            format: () => { return EXPECTED_DATE; }
          };
        });

        handler(mockReq, mockResp, null);

        expect(mockResp.setHeader.mock.calls.length).toBe(1);
        expect(mockResp.setHeader.mock.calls[0][0]).toBe('content-type');
        expect(mockResp.setHeader.mock.calls[0][1]).toBe('application/json');

        expect(mockResp.send.mock.calls.length).toBe(1);
        expect(mockResp.send.mock.calls[0][0]).toBe(JSON.stringify({
            statusCode: '200',
            message: `The time in Asia/Shanghai is: ${EXPECTED_DATE}`
        }, null, '    '));
    });

    it('Should return an error if the provided timezone does not exists', async () => {
        const mockReq = {
            queries: {
                tz: TIMEZONE
            }
        }
        const mockResp = {
            setHeader: jest.fn(),
            send: jest.fn()
        }

        tz.names = () => { return []; };

        handler(mockReq, mockResp, null);

        expect(mockResp.setHeader.mock.calls.length).toBe(1);
        expect(mockResp.setHeader.mock.calls[0][0]).toBe('content-type');
        expect(mockResp.setHeader.mock.calls[0][1]).toBe('application/json');
    
        expect(mockResp.send.mock.calls.length).toBe(1);
        expect(mockResp.send.mock.calls[0][0]).toBe(JSON.stringify({
            statusCode: '400',
            message: `Unknown timezone ${TIMEZONE}.`,
            timezones: []
        }, null, '    '));
      });
});

