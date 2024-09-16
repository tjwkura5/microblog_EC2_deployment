# https://flask.palletsprojects.com/en/3.0.x/testing/
import pytest

from  microblog import app
from app import db
from app.models import User

@pytest.fixture
def client():
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    app.config['TESTING'] = True
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
            yield client
            db.session.rollback()
            db.drop_all()

@pytest.fixture
def mock_user():
    # Create a test user in the database
    user = User(username="testuser1", email="test@example.com")
    user.set_password('password')
    db.session.add(user)
    db.session.commit()
    return user

@pytest.fixture
def auth_header(mock_user):
    # Generate a valid token for the test user
    token = mock_user.get_token()
    return {
        'Authorization': f'Bearer {token}'
    }

def test_redirect(client):
    response = client.get('/', follow_redirects=True)
    assert response.status_code == 200
    assert b'<title>Sign In - Microblog</title>' in response.data

def test_users(client, auth_header):
    response = client.get('/api/users', headers=auth_header)
    assert response.status_code == 200
    data = response.get_json()
    assert 'items' in data
    assert len(data['items']) > 0
    assert data['items'][0]['username'] == 'testuser1'

def test_login(client, mock_user):
    # logging in the user
    login_data = {
        'username': mock_user.username,
        'password': 'password',  
        'remember_me': True,
        'submit': True
    }
    # Perform a POST request to the /login endpoint
    response = client.post('/auth/login', data=login_data, follow_redirects=True)
    assert response.status_code == 200
    assert b'<title>Sign In - Microblog</title>' in response.data




