## ResourceFinder

ResourceFinder is a simple Rails gem that finds resource for controller from request parameters. It lets you write less codes and eradicates repeat resource finding codes completely in every controller.

### Purpose

Generally, when we need to find the resource in controller for actions, we can do like this:

```ruby
class UsersController < ApplicationController

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
  end

  def destroy
    @user = User.find(params[:id])
  end

end
```

Or, we always use `before_action` makes it looks better:

```ruby
class UsersController < ApplicationController
  before_action :find_user, only: [:show, :edit, :update, :destroy]

  def show
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def find_user
    @user = User.find(params[:id])
  end
end
```

What we done above can solve the repeate codes problem in a single controller, but there will be a lots of controllers in Rails project, we need to define a lots of `find_xxx` methods in its controller. So ResourceFinder is designed to solve this problem.

### Installation

Add the gem to your Gemfile:

    gem 'resource_finder'

Install the gem with bundler:

    bundle install

### Usage

To add ResourceFinder in your Rails project, first put it included in your ApplicationController.

```ruby
class ApplicationController
  include ResourceFinder
end
```

And then you can use it in every controllers which inherited from ApplicationController.

```ruby
class UsersController < ApplicationController
  findable :user

  def destroy
    @user.destroy # now you can just call @user here
  end
end
```

When nested resources, posts belongs to user.

```ruby
class PostsController < ApplicationController
  findable :user
  findable :post, scope: :user
end
```

### Configuration

Basicly, you can set `only` or `except` options like `before_action`, basides there are some useful keys for options:

  - model
  - query
  - in
  - of
  - scope
  - lazy
  - silent

#### Overriding the default model

By default, ResourceFinder will detect model based on the object your set by `findable`.

```ruby
findable :customer # default Customer model
findable :customer, model: User
```

#### Specific the key in parameters as query content in DB

By default, ResourceFinder gets the query content by query name `object_id` in parameters.

```ruby
class PostsController < ApplicationController
  findable :user # params[:user_id]
end
```

But if the object model is same as the model deduced from current controller name. ResourceFinder will use `id` to get query content from parameters.

```ruby
class UsersController < ApplicationController
  findable :user # params[:id]
  findable :customer, model: User # params[:id]
end
```

You can also pass a lambda/array/string/symbol to `query` options.

```ruby
findable :user, query: :uuid # params[:uuid]
findable :user, query: [:user, :id] # params[:user][:id]
findable :user, query: -> (params) { your_decoder params[:encode_user_id] }
```

#### Set query columns for ActiveReord

By default, ResourceFinder uses `id` to query.

```ruby
findable :user # query in column: [:id]
findable :user, in: :uuid # query in column: [:uuid]
findable :user, in: [:id, :uuid] # query in columns: [:id, :uuid]
```

#### Scope limitation

For nested resources, maybe you want to limit the resource.

```ruby
findable :user
findable :post, scope: :user # make sure @post is one of @user.posts
```

#### Find resource on an existed resource

```ruby
findable :user
findable :city, of: :user # same as: @city = user.city
```

#### Use it without setting instance variable

Sometimes, you prefer to improve performance, `lazy: true` can let ResourceFinder be lazy load, also, there will be no any instance variables generated any more.

```ruby
class UsersController < ApplicationController
  findable :user, lazy: true

  def show
    user = findable(:user)
    render json: user
  end
end
```

#### Exception silent

By default, ResourceFinder will be allowed to raise error during source finding. For example: RecordNotFound. You can set `silent: true` to prevent error raised.

```ruby
class UsersController < ApplicationController
  findable :user, silent: true

  def show
    # if user record not found
    # @user will be eq: nil
  end
end
```

### License

Released under the [MIT](http://opensource.org/licenses/MIT) license. See LICENSE file for details.
