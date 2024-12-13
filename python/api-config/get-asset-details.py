import json
from jinja2 import Environment, FileSystemLoader, Undefined
import yaml

upstream_list = []
def yaml_to_dict(file_path):
    with open(file_path, 'r') as file:
        # Parse the YAML file into a Python dictionary
        data_dict = yaml.safe_load(file)
    return data_dict

yaml_properties_dict = yaml_to_dict('us-dev.yaml')

print(yaml_properties_dict['asset']['description'])




