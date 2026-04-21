from setuptools import setup, find_packages

setup(
    name="altoscope-pipeline",
    version="0.1.0",
    packages=find_packages(where="src"),
    install_requires=[
        "beautifulsoup4>=4.13",
        "pandas>=2.2",
        "playwright>=1.50",
        "requests>=2.32",
        "psycopg2-binary",
        "python-dotenv",
        "boto3",
    ],
    package_dir={"": "src"},
    python_requires=">=3.10",
    author="Darin Hall",
    author_email="darin@altoscope.so",
    description="Scraping pipeline for Altoscope — discovers, extracts, normalizes, and persists camera gear specs",
    url="https://github.com/darinhall/Altoscope",
)