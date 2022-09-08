from setuptools import setup

# This call to setup() does all the work
setup(
    name="openlocationcode",
    version="1.0.1",
    description="Python library for Open Location Code (Plus Codes)",
    url="https://github.com/google/open-location-code",
    author="Google",
    author_email="open-location-code@googlegroups.com",
    license="Apache 2.0",
    classifiers=[
        "Programming Language :: Python :: 2.7",
        "Programming Language :: Python :: 3.6",
    ],
    packages=["openlocationcode"],
    include_package_data=True,
    install_requires=[],
)