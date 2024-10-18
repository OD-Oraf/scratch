import json
from jinja2 import Environment, FileSystemLoader, Undefined
import yaml

def yaml_to_dict(file_path):
    with open(file_path, 'r') as file:
        # Parse the YAML file into a Python dictionary
        data_dict = yaml.safe_load(file)
    return data_dict

# Load the Jinja2 environment
jinja2_env = Environment(loader=FileSystemLoader('.'), undefined=Undefined)

# Load the json template
template = jinja2_env.get_template('api-config.json')

# Convert properties to a dictionary
yaml_properties_dict = yaml_to_dict('us-dev.yaml')
print(f'yaml properties: {yaml_properties_dict}')

# Render the template with parameters
rendered_json = template.render(yaml_properties_dict)
# Convert the rendered string back to JSON
json_data = json.loads(rendered_json)

# Print the result
print(json.dumps(json_data, indent=4))

# with open('api-config.json', "w") as f:
#     json.dump(json_data, f, sort_keys=True, indent=4, separators=(',', ': '))