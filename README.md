
# Deployed app link:

https://elrc-f94dd4361a25.herokuapp.com/

---

## Getting Started

### Prerequisites

- [Ruby 3.3.0](https://www.ruby-lang.org/en/)
- [Rails](https://rubyonrails.org/)
- [Bundler](https://bundler.io/)

### Installation

Clone repository

```
git clone https://github.com/SaiNithin001/OLEI.git
```

Install all dependencies

```
cd OLEI/rails_root
bundle install
```

## Usage

### Run locally

Create master key

```
cd rails_root
echo "<master key here>" > ./config/master.key
```

Running database locally

`bundle config set --local without 'production' ` (Using SQLite only)

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

* [Legacy Code](https://github.com/tamu-edu-students/csce606-ELRC-OLEI_Project)
