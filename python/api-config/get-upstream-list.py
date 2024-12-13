import json
from jinja2 import Environment, FileSystemLoader, Undefined
import yaml

upstream_list = []
def yaml_to_dict(file_path):
    with open(file_path, 'r') as file:
        # Parse the YAML file into a Python dictionary
        data_dict = yaml.safe_load(file)
    return data_dict

def iterate_yaml(data):
    global upstream_list
    if isinstance(data, dict):
        for key, value in data.items():
            if isinstance(value, (dict, list)):
                iterate_yaml(value)
            else:
                print(f"{key}: {value}")
                if key.startswith('upstream'):
                    upstream_list.append(value)
    elif isinstance(data, list):
        for item in data:
            iterate_yaml(item)
    return upstream_list

yaml_properties_dict = yaml_to_dict('us-dev.yaml')

print(yaml_properties_dict.items())

# iterate_yaml(yaml_properties_dict)

print(upstream_list)




