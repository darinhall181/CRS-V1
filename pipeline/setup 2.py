from setuptools import setup, find_packages

setup(
    name="CRS-V1",
    version="0.1.0",
    packages=find_packages(where="src"),
    install_requires=[
        "beautifulsoup4>=4.13.4",
        "certifi>=2025.7.14",
        "charset-normalizer>=3.4.2",
        "greenlet>=3.2.3",
        "idna>=3.10",
        "pandas>=2.2.3",
        "playwright>=1.54.0",
        "pyee>=13.0.0",
        "requests>=2.32.4",
        "soupsieve>=2.7",
        "typing_extensions>=4.14.1",
        "urllib3>=2.5.0",
    ],
    package_dir={"": "src"},
    python_requires=">=3.10",
    author="Darin Hall",
    author_email="contact@darinhall.com",
    description="Database for hosting camera gear",
    long_description=open("README.md").read() if __import__("os").path.exists("README.md") else "",
    long_description_content_type="text/markdown",
    url="https://github.com/darinhall/CRS-V1",
    project_urls={
        "Bug Reports": "https://github.com/darinhall/CRS-V1/issues",
        "Source": "https://github.com/darinhall/CRS-V1",
    },
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
)