# frozen_string_literal: true

module Dashboard
  Tile = Data.define(:label, :value, :note)

  class << self
    def for(user, params: {})
      dashboard =
        if user.global_admin?
          GlobalAdmin.new
        elsif user.organization_admin?
          OrganizationAdmin.new(user: user)
        elsif user.teacher?
          Teacher.new(user: user, filter: params[:group])
        else
          Student.new(user: user)
        end

      dashboard.load
    end
  end
end
