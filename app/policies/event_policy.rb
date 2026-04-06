class EventPolicy < ApplicationPolicy

  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.present?
  end

  def update?
    record.owner_id == user&.id
  end

  def destroy?
    record.owner_id == user&.id
  end

  class Scope < ApplicationPolicy::Scope

    def resolve
      scope.all
    end

  end

end
