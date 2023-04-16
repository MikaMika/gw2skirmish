from flask import Flask, render_template, jsonify
from datetime import datetime, timezone

from .anet import get_matches, get_worlds, get_world_by_id
from .gpt_math import gpt_calculate_scores
from .match_math import calculate_scores

app = Flask(__name__)


@app.route('/')
@app.route('/index/')
def hello():
    matches = get_matches()
    worlds = get_worlds()
    worlds_by_id = get_world_by_id(worlds)
    calculate_scores(matches, worlds_by_id)
    now_utc = datetime.now(timezone.utc)
    return render_template('homepage.html', matches=matches, now_utc=now_utc, worlds=worlds, worlds_by_id=worlds_by_id)


@app.route('/gpt')
def gpt():
    matches = get_matches()
    worlds = get_worlds()
    worlds_by_id = get_world_by_id(worlds)
    gpt_calculate_scores(matches)
    now_utc = datetime.now(timezone.utc)
    return render_template('gptpage.html', matches=matches, now_utc=now_utc, worlds=worlds, worlds_by_id=worlds_by_id)


@app.route('/world/<int:world_id>')
def about(world_id):
    worlds_by_id = get_world_by_id()
    if world_id in worlds_by_id:
        return render_template('world.html', world=worlds_by_id[world_id])

    return render_template('404.html'), 404

@app.route('/match/<match_id>')
def match(match_id):
    matches = get_matches()
    worlds = get_worlds()
    worlds_by_id = get_world_by_id(worlds)
    calculate_scores(matches, worlds_by_id)
    now_utc = datetime.now(timezone.utc)
    match = [match for match in matches if match['id'] == match_id]
    if match:
        return render_template('match.html', match=match[0], now_utc=now_utc, worlds=worlds, worlds_by_id=worlds_by_id)

    return render_template('404.html'), 404

@app.route('/api/scores')
def api_scores():
    matches = get_matches()
    worlds = get_worlds()
    worlds_by_id = get_world_by_id(worlds)
    calculate_scores(matches, worlds_by_id)
    return jsonify(matches)
