**Link to the Team Working Agreement:**
https://drive.google.com/file/d/16uUZbFhEMnh5MCQcVUXWtCvOM4edJY95/view?usp=sharing

---

# Deployed app link:

https://elrc-6ad76821be30.herokuapp.com/

---

# Readme:

<!--[![Test Coverage](https://api.codeclimate.com/v1/badges/62f4dd4fb092b4211973/test_coverage)](https://codeclimate.com/repos/65caed0abc0d27237b1794c9/test_coverage) 
[![Maintainability](https://api.codeclimate.com/v1/badges/62f4dd4fb092b4211973/maintainability)](https://codeclimate.com/repos/65caed0abc0d27237b1794c9/maintainability) -->

![rubocop](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/barnden/c7b2d5e19079e12445b300407e383294/raw/badge.json)

- [Deployed Application](https://elrc-app-dfcfc7cd862b.herokuapp.com/)
- [Code Climate Reports](https://codeclimate.com/github/tamu-edu-students/csce606-ELRC-OLEI_Project)
- [GitHub Repo](https://github.com/tamu-edu-students/csce606-ELRC-OLEI_Project)
- [Pivotal Tracker](https://www.pivotaltracker.com/n/projects/2720653)
- [Slack](https://app.slack.com/client/T07NQ098G0G/C07NE1HS2BB)

<details open="open">
<summary>Table of Contents</summary>

- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)

</details>

---

## Getting Started

### Prerequisites

- [Ruby 3.3.0](https://www.ruby-lang.org/en/)
- [Rails](https://rubyonrails.org/)
- [Bundler](https://bundler.io/)
- [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli)

### Installation

Clone repository

```
git clone https://github.com/tamu-edu-students/csce606-ELRC-OLEI_Project.git
```

Install all dependencies

```
cd csce606-ELRC-OLEI_Project/rails_root
bundle install
```

## Usage

### Run locally

Create master key (obtain master key either via Dr.Ritchey or by emailing team members in contact section)

```
cd rails_root
echo "<master key here>" > ./config/master.key
```

Running database locally

`bundle config set --local without 'production' ` (Using SQLite only otherwise ``brew install pg``)

Generate database

```
rails db:migrate
rails db:seed
```

Start server

```
rails server
```

### Run tests

Setup test database

```
rails db:test:prepare
```

Run rspec tests

```
bundle exec rspec
```

Run cucumber tests

```
bundle exec cucumber
```

### Deploy

Create Heroku application

```
heroku create <app_name>
```

Add buildpacks

```
heroku buildpacks:add https://github.com/timanovsky/subdir-heroku-buildpack.git --app <app-name>
heroku buildpacks:add heroku/ruby --app <app-name>
```

Add config vars

```
heroku config:set PROJECT_PATH=rails_root --app <app-name>
heroku config:set RAILS_MASTER_KEY=<master key here> --app <app-name>
```

Install [Heroku Postgres](https://elements.heroku.com/addons/heroku-postgresql) and attach to application

Push to heroku app

```
git push heroku main
```

Generate database

```
heroku run rails db:migrate
heroku run rails db:seed
```

[Github Integration with Heroku](https://devcenter.heroku.com/articles/github-integration)

Set up Github Action (Different from Github Integration with Heroku)
1. Set up ```secrets.RAILS_MASTER_KEY``` in your project Github Repository
2. Set up ```secrets.GIST_SECRET``` in your project Github Repository by valid token with gist scope
3. Set up ```secrets.GIST_ID``` (Create your own gist, and set up the gist ID in your project Github Repository)

## Contacts

* Chih-Chuan Hsu <agenuinedream@tamu.edu>
* Kunal Somendrasingh
* Manoj Gurram
* Manoj Peta
* Sai Aakarsh Padma
* Sai Nithin
* Vinayaka Hegde
* [Legacy Code](https://github.com/tamu-edu-students/csce606-ELRC-Synergistic-Leadership-Theory)
