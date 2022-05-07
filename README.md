cloudfoundry Github Action
==========================

## How to use

Create a github action that will listen to a new deployment and then push your cf app

```yml

name: Deploy to Cloud Foundry
on: push
    
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name : CloudFoundry push application
        uses: brickendon/cloudfoundry@main
        with:
          api:      ${{ secrets.CF_API }}
          org:      ${{ secrets.CF_ORG }}
          space:    ${{ secrets.CF_SPACE }}
          username: ${{ secrets.CF_USERNAME }}
          password: ${{ secrets.CF_PASSWORD }}
          manifest: manifest.yml
          validate: true          # set to false if you don't want to validate ssl
```

## Further Options

By passing the  ``appdir`` parameter you can define what directory should be used for your CF APP. This can be usefull if you have multiple cf apps in one repository.

If you're not sure about the used directoy that is created in the docker container you can make use of the ``debug`` parameter to list all directories in the output of the actions log

```yml

name: Deploy to Cloud Foundry
on:
  push:
    paths:
    - 'PATH/TO/YOUR/APP/**'
    
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name : CloudFoundry push application with different directory
        uses: brickendon/cloudfoundry@main
        with:
          appdir:   './api/'       # use the appdir option to select a specif folder where the cf app is stored
          api:      ${{ secrets.CF_API }}
          org:      ${{ secrets.CF_ORG }}
          space:    ${{ secrets.CF_SPACE }}
          username: ${{ secrets.CF_USERNAME }}
          password: ${{ secrets.CF_PASSWORD }}
          manifest: manifest.yml
          validate: true          
```