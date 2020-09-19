# Dockerfile for Liquid Feedback

[Liquid Feedback](http://liquidfeedback.org) is an [open-source application](https://www.public-software-group.org/liquid_feedback) that enables internet platforms for proposition development and decision making.

The project's source code has a lot of dependencies and requires a lot of tedious steps to build. This Dockerfile simplifies this process and allows interested developers and organizations to quickly build and run a Liquid Feedback server using a [Docker](http://docker.io) container.

## How to use

To build an image go to the Dockerfile dir and do:

    docker build -t liquid-feedback .
    
To run the server do:

    docker run -p 127.0.0.1:8080:8080 liquid-feedback
    
And connect a browser to http://localhost:8080 and login with user admin and empty password
