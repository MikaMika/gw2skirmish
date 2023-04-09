from flask import Flask, render_template
from datetime import datetime, timezone

from .anet import get_matches,get_worlds,get_world_by_id
from .match_math import calculate_scores

app = Flask(__name__)

@app.route('/')
@app.route('/index/')
def hello():
    matches = get_matches()
    worlds = get_worlds()
    worlds_by_id = get_world_by_id(worlds)
    calculate_scores(matches,worlds_by_id)
    now_utc = datetime.now(timezone.utc)
    return render_template('homepage.html', matches=matches,now_utc=now_utc,worlds=worlds,worlds_by_id=worlds_by_id)

@app.route('/world/<int:world_id>')
def about(world_id):
    worlds_by_id = get_world_by_id()
    if world_id in worlds_by_id:
        return render_template('world.html', world=worlds_by_id[world_id])
       
    return render_template('404.html'), 404