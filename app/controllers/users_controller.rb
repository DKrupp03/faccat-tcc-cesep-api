class UsersController < ApplicationController
	before_action(:authenticate_user!, only: [:index])

	def index
		render(json: { users: User.all })
	end

	def get_current_user
		render(json: { user: current_user })
	end
end
