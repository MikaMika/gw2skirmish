# api

This is the Flask backend.

This will provide the web APIs for gw2skirmish. Currently just serves results in simple html pages.

# Setup

## Requisites
- Python 3.7 at least

## Environment setup (optional)
Set up a Python virtual environment.
- You're IDE may ask to do this for you, let it do so if you'd prefer 
```sh
# assuming you're in the repo root folder (not in ./api)

python3 -m venv venv
```
If `python3` is missing `python` should work as long as it's 3.7+

Activate environment
```
source venv/bin/activate
```

Install requirements
```
pip install -r api/requirements.txt
```

## Run app
Run flask app locally
```
cd api
flask run 
```

Launches web app at http://127.0.0.1:5000 
- Launches in debug mode with automatic reload on changes





