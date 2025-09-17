const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');
const syntheticsConfiguration = synthetics.getConfiguration();

const apiCanaryBlueprint = async function () {
    // Configure the request
    syntheticsConfiguration.setConfig({
        restrictedHeaders: [], // Value of these headers will be redacted from the report
        restrictedUrlParameters: [] // Values of these URL parameters will be redacted from the report
    });

    // API endpoints to test
    const apiEndpoints = [
        {
            url: 'https://${domain_name}/health',
            name: 'Health Check',
            expectedStatus: 200
        },
        {
            url: 'https://${domain_name}/api/network/status',
            name: 'Network Status API',
            expectedStatus: 200
        },
        {
            url: 'https://${domain_name}/api/metrics',
            name: 'Metrics API',
            expectedStatus: 200
        }
    ];

    for (const endpoint of apiEndpoints) {
        await synthetics.executeStep(endpoint.name, async function () {
            const requestOptions = {
                hostname: '${domain_name}',
                method: 'GET',
                path: endpoint.url.replace('https://${domain_name}', ''),
                port: 443,
                protocol: 'https:',
                headers: {
                    'User-Agent': 'CloudWatch-Synthetics'
                }
            };

            const response = await synthetics.executeHttpStep(endpoint.name, requestOptions);
            
            // Validate response status
            if (response.statusCode !== endpoint.expectedStatus) {
                throw new Error(`Expected status ${endpoint.expectedStatus}, got ${response.statusCode}`);
            }

            // Validate response time
            if (response.responseTime > 2000) {
                log.warn(`High response time: ${response.responseTime}ms for ${endpoint.name}`);
            }

            // Log success
            log.info(`${endpoint.name} completed successfully - Status: ${response.statusCode}, Response Time: ${response.responseTime}ms`);
        });
    }

    return "success";
};

exports.handler = async () => {
    return await synthetics.executeStep('apiCanaryBlueprint', apiCanaryBlueprint);
};
