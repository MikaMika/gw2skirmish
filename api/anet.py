import json
import requests

def get_matches():
    return fetch('wvw/matches')

def get_worlds():
    return fetch('worlds')

def get_world_by_id(worlds=None):
    if worlds is None:
        worlds = get_worlds()
    world_by_id = {item['id']: item for item in worlds}
    return world_by_id

def fetch(resource):
    url = f'https://api.guildwars2.com/v2/{resource}?ids=all'
    r = requests.get(url)
    # TODO: cache/persist response
    return r.json()
