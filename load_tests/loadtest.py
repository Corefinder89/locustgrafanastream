from locust import HttpUser, task, between

class JsonAPI(HttpUser):
    wait_time = between(1, 2)

    host = "https://jsonplaceholder.typicode.com"

    @task
    def get_posts(self):
        self.client.get("/posts")

    @task
    def get_comments(self):
        self.client.get("/posts/1/comments")

    @task
    def get_photos(self):
        self.client.get("/photos")

    @task
    def get_todos(self):
        self.client.get("/todos")

    @task
    def get_users(self):
        self.client.get("/users")