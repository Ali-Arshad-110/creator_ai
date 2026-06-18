# CreatorAI Backend

FastAPI application that serves the analysis engine, manages history with Supabase, and runs LLM evaluations.

## Local Setup

### 1. Prerequisites
- Python 3.12+
- Docker (optional)

### 2. Install Dependencies
```bash
python -m venv venv
# Windows:
.\venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

pip install -r requirements.txt
```

### 3. Environment Variables
Copy `.env.example` to `.env` and fill in your keys:
```bash
cp .env.example .env
```

### 4. Running the App
Start the development server with auto-reload:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
The API documentation will be available at [http://localhost:8000/docs](http://localhost:8000/docs) (when `DEBUG=true`).

### 5. Running Tests
Run tests using pytest:
```bash
pytest
```
For coverage:
```bash
pytest --cov=app tests/
```
