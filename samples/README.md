# Diametric Samples

This directory contains samples of Diametric.

## Rails app sample

rails-sample holds a simple Rails app.
This app uses datomic's REST service. Beofre staring rails, make sure datomic REST service is up and running.

```
cd [datomic home directory]
bin/rest 9000 free datomic:mem://
```

Then, you can run this Rails app as in below:

```
cd rails-sample
bundle
rails s
```

Go to http://localhost:3000/post on your browser.