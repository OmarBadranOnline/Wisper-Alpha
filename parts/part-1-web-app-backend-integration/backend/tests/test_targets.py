def test_create_and_list_target(client):
    r = client.post("/api/v1/targets", json={
        "name": "Test Corp",
        "primary_domain": "testcorp.com",
        "tags": ["bug-bounty"],
        "owner": "alice",
    })
    assert r.status_code == 201
    data = r.json()["data"]
    assert data["primary_domain"] == "testcorp.com"
    tid = data["id"]

    r2 = client.get("/api/v1/targets")
    assert r2.status_code == 200
    assert r2.json()["data"]["total"] >= 1

    r3 = client.get(f"/api/v1/targets/{tid}")
    assert r3.status_code == 200
    assert r3.json()["data"]["id"] == tid


def test_update_target(client):
    r = client.post("/api/v1/targets", json={
        "name": "Old Name",
        "primary_domain": "oldname.io",
    })
    tid = r.json()["data"]["id"]
    r2 = client.patch(f"/api/v1/targets/{tid}", json={"name": "New Name"})
    assert r2.status_code == 200
    assert r2.json()["data"]["name"] == "New Name"


def test_delete_target(client):
    r = client.post("/api/v1/targets", json={
        "name": "Delete Me",
        "primary_domain": "deleteme.net",
    })
    tid = r.json()["data"]["id"]
    r2 = client.delete(f"/api/v1/targets/{tid}")
    assert r2.status_code == 200
    r3 = client.get(f"/api/v1/targets/{tid}")
    assert r3.status_code == 404


def test_invalid_domain(client):
    r = client.post("/api/v1/targets", json={
        "name": "Bad",
        "primary_domain": "NOT A DOMAIN!!",
    })
    assert r.status_code == 422
