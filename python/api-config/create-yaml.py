import yaml

# Sample dictionary
output_data = {
    'route1': {
        'path': '/route1',
        'methods': 'GET',
        'upstream1': 'https://goolge.com',
        'upstream2': 'https://firefox.com',

    },
    'route2': {
        'path': '/route1',
        'methods': 'GET',
        'upstream1': 'https://facebook.com'
    },
    'asset': {
        'id': 'mule-health-fgw',
        'version': "1.0.0"
    }
}

# Convert dictionary to YAML and write to a file
with open('meta.yaml', 'w') as file:
    yaml.dump(output_data, file, allow_unicode=True, default_flow_style=False)

print("YAML file created successfully.")