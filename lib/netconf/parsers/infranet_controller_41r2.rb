require 'set'

module InfranetController41r2
  def self.has_capability? cap
    cap =~ /http:\/\/xml.juniper.net\/dmi\/ive-ic\/4.1R2/ ||
    cap =~ /http:\/\/xml.juniper.net\/dmi\/ive-ic\/4.1R5/ ||
    cap =~ /http:\/\/xml.juniper.net\/dmi\/ive-ic\/4.1R7/
  end

  def new_role name, description
    edit_config('running') do |xml|
      build(xml, 'configuration/users/user-roles/user-role') do |xml|
        xml.name name
        xml.general do
          xml.overview do
            xml.description description
          end
        end
      end
    end
  end

  def get_role name
    role = nil
    get_config_items('configuration/users/user-roles/user-role', name) do |reader|
      role =  XML::Document.string(reader.read_outer_xml)
    end
    return role
  end

  def change_role_name old_name, new_name
    # get existing role config
    new_role = get_role(old_name)
    raise "Role does not exist" if (new_role.nil?)

    # change name in config
    name_tag = new_role.find_first('dmi:name', "dmi:#{new_role.root.namespaces.default}")
    name_tag.content = new_name

    # upload new role config
    edit_config('running') do |xml|
      build(xml, 'configuration/users/user-roles/user-role') do |xml|
        xml << new_role.root.inner_xml
      end
    end

    # add new role to all users
    realms = get_role_mappings
    realms.each do |realm, mappings|
      mappings.each do |name, roles|
        if (roles.include?(old_name) && ! roles.include?(new_name))
          roles << new_name
          set_mapping_roles(realm, name, roles)
        end
      end
    end

    # re-map resource access policies
    resources = get_role_resources(old_name)
    resources.each do |resource_name|
      roles = get_resource_roles(resource_name)
      roles << new_name
      roles.delete(old_name)
      set_resource_roles(resource_name, roles)
    end

    # re-map ipsec policies
    ipsec_policies = get_role_ipsec_policies(old_name)
    ipsec_policies.each do |ipsec_policy_name|
      roles = get_ipsec_policy_roles(ipsec_policy_name)
      roles << new_name
      roles.delete(old_name)
      set_ipsec_policy_roles(ipsec_policy_name, roles)
    end

    # re-map auth table entries
    auth_tables = get_role_auth_tables(old_name)
    auth_tables.each do |auth_table_name|
      roles = get_auth_table_roles(auth_table_name)
      roles << new_name
      roles.delete(old_name)
      set_auth_table_roles(auth_table_name, roles)
    end

    # re-map ip address pools
    address_pools = get_role_address_pools(old_name)
    address_pools.each do |pool_name|
      roles = get_address_pool_roles(pool_name)
      roles << new_name
      roles.delete(old_name)
      set_address_pool_roles(pool_name, roles)
    end

    # remove old role from users
    realms.each do |realm, mappings|
      mappings.each do |name, roles|
        if (roles.include?(old_name))
          roles.delete(old_name)
          set_mapping_roles(realm, name, roles)
        end
      end
    end

    # delete old role
    delete_role(old_name)
  end

  def change_role_description name, description
    edit_config('running') do |xml|
      build(xml, "configuration/users/user-roles/user-role") do |xml|
        xml.name name
        xml.description description
      end
    end
  end

  def delete_role name
    edit_config('running') do |xml|
      build(xml, "configuration/users/user-roles") do |xml|
        xml.tag!('user-role', 'operation' => 'delete') do
          xml.name name
        end
      end
    end
  end

  def add_role_to_mapping realm_name, mapping, role_name, user_names=[]
    roles = get_mapping_roles(realm_name, mapping)
    roles << role_name
    set_mapping_roles(realm_name, mapping, roles, user_names)
  end

  def remove_role_from_mapping realm_name, mapping, role_name, user_names=[]
    roles = get_mapping_roles(realm_name, mapping)
    roles.delete(role_name)
    set_mapping_roles(realm_name, mapping, roles, user_names)
  end

  def set_mapping_roles realm_name, mapping, roles, user_names=[]
    edit_config('running') do |xml|
      build(xml, "configuration/users/user-realms/realm") do |xml|
        xml.name realm_name
        if (roles.size > 0)
          build(xml, 'role-mapping-rules/rule') do 
            xml.name mapping, 'operation' => 'merge'
            if (user_names.size > 0)
              xml.tag!('user-name') do
                xml.test 'is'
                user_names.each do |user_name|
                  xml.tag!('user-names', user_name)
                end
              end
            end
            roles.each do |role|
              xml.roles role
            end
          end
        else
          build(xml, 'role-mapping-rules') do 
            xml.rule('operation' => 'delete') do 
              xml.name mapping
            end
          end
        end
      end
    end
  end

  def new_resource name, description
    edit_config 'running' do |xml|
      build(xml, 'configuration/uac/infranet-enforcer/resource-access-policies') do |xml|
        xml.tag!('resource-access-policy', 'operation' => 'create') do |xml|
          xml.name name
          xml.description description
          xml.action 'deny-access'
          xml.apply 'selected-roles'
          xml.resources '0.0.0.0/0'
        end
      end
    end
  end

  def change_resource_name old_name, new_name
    raise "not implemented"
  end

  def change_resource_description name, description
    edit_config 'running' do |xml|
      build(xml, 'configuration/uac/infranet-enforcer/resource-access-policies') do |xml|
        xml.tag!('resource-access-policy', 'operation' => 'merge') do |xml|
          xml.name name
          xml.description description
        end
      end
    end
  end

  def set_resource_access name, access
    edit_config 'running' do |xml|
      build(xml, 'configuration/uac/infranet-enforcer/resource-access-policies') do |xml|
        xml.tag!('resource-access-policy', 'operation' => 'merge') do |xml|
          xml.name name
          xml.action 'allow-access'
          xml.resources access
        end
      end
    end
  end

  def add_role_to_resource resource_name, role_name
    roles = get_resource_roles(resource_name)
    roles << role_name
    set_resource_roles(resource_name, roles)
  end

  def remove_role_from_resource resource_name, role_name
    roles = get_resource_roles(resource_name)
    roles.delete(role_name)
    set_resource_roles(resource_name, roles)
  end

  def delete_resource name
    edit_config 'running' do |xml|
      build(xml, 'configuration/uac/infranet-enforcer/resource-access-policies') do |xml|
        xml.tag!('resource-access-policy', 'operation' => 'delete') do |xml|
          xml.name name
        end
      end
    end
  end

  def new_ipsec_policy name, description, routes, exceptions=[]
    edit_config 'running' do |xml|
      build(xml, 'configuration/uac/infranet-enforcer/ipsec-routing-policies') do |xml|
        xml.tag!('ipsec-routing-policy', 'operation' => 'create') do
          xml.name name
          xml.description description
          xml.manual do
            routes.each do |route|
              xml.resources route
            end
            exceptions.each do |exception|
              xml.tag!('exception-to-resource', exception)
            end
          end
          xml.apply('selected-roles')
        end
      end
    end
  end

  def change_ipsec_policy_description name, description
    edit_config 'running' do |xml|
      build(xml, 'configuration/uac/infranet-enforcer/ipsec-routing-policies') do |xml|
        xml.tag!('ipsec-routing-policy', 'operation' => 'merge') do
          xml.name name
          xml.description description
        end
      end
    end
  end

  def set_ipsec_policy_routes name, routes
    edit_config 'running' do |xml|
      build(xml, 'configuration/uac/infranet-enforcer/ipsec-routing-policies') do |xml|
        xml.tag!('ipsec-routing-policy', 'operation' => 'merge') do
          xml.name name
          xml.manual do
            routes.each do |route|
              xml.resources route
            end
          end
        end
      end
    end
  end

  def set_ipsec_policy_exceptions name, exceptions
    edit_config 'running' do |xml|
      build(xml, 'configuration/uac/infranet-enforcer/ipsec-routing-policies') do |xml|
        xml.tag!('ipsec-routing-policy', 'operation' => 'merge') do
          xml.name name
          xml.manual do
            exceptions.each do |exception|
              xml.tag!('exception-to-resource', exception)
            end
          end
        end
      end
    end
  end

  def add_role_to_ipsec_policy ipsec_policy, role_name
    roles = get_ipsec_policy_roles(ipsec_policy)
    roles << role_name
    set_ipsec_policy_roles(resource_name, roles)
  end

  def remove_role_from_ipsec_policy ipsec_policy, role_name
    roles = get_ipsec_policy_roles(ipsec_policy)
    roles.delete(role_name)
    set_ipsec_policy_roles(resource_name, roles)
  end

  def set_object_roles object_path, object_name, roles
    object_path = object_path.split(/\//)
    object_tag = object_path.pop
    object_path = object_path.join('/')

    edit_config 'running' do |xml|
      build(xml, object_path) do |xml|
        xml.tag!(object_tag, 'operation' => 'merge') do |xml|
          xml.name object_name
          if roles.size > 0
            roles.each do |role|
              xml.roles role
            end 
          else
            xml.roles
          end
        end
      end
    end
  end

  def set_auth_table_roles name, roles
    set_object_roles('configuration/uac/infranet-enforcer/auth-table-mapping-policies/auth-table-mapping-policy', name, roles)
  end

  def set_address_pool_roles name, roles
    set_object_roles('configuration/uac/infranet-enforcer/ip-address-pools-policies/ip-address-pools-policy', name, roles)
  end

  def set_resource_roles name, roles
    set_object_roles('configuration/uac/infranet-enforcer/resource-access-policies/resource-access-policy', name, roles)
  end

  def set_ipsec_policy_roles name, roles
    set_object_roles('configuration/uac/infranet-enforcer/ipsec-routing-policies/ipsec-routing-policy', name, roles)
  end

  def get_roles_for_object object_path, object_name
    roles = Set.new
    object_tag = object_path.split(/\//)
    object_tag = object_tag.last
    get_config_items(object_path, object_name) do |reader|
      while(reader.read)
        break if (reader.name == object_tag)
        next if (reader.node_type == XML::Reader::TYPE_END_ELEMENT)
        if (reader.name == 'roles')
          role = reader.read_string
          roles << role unless (role.empty?)
        end
      end
    end
    return roles
  end

  def get_auth_table_roles auth_table
    get_roles_for_object('configuration/uac/infranet-enforcer/auth-table-mapping-policies/auth-table-mapping-policy', auth_table)
  end

  def get_address_pool_roles address_pool
    get_roles_for_object('configuration/uac/infranet-enforcer/ip-address-pools-policies/ip-address-pools-policy', address_pool)
  end

  def get_resource_roles resource_name
    get_roles_for_object('configuration/uac/infranet-enforcer/resource-access-policies/resource-access-policy', resource_name)
  end

  def get_ipsec_policy_roles ipsec_policy_name
    get_roles_for_object('configuration/uac/infranet-enforcer/ipsec-routing-policies/ipsec-routing-policy', ipsec_policy_name)
  end

  def get_realms
    realms = Set.new
    get_config_items('configuration/users/user-realms/realm', '', ['name']) do |reader|
      while(reader.read)
        break if (reader.name == 'realm')
        next if (reader.node_type == XML::Reader::TYPE_END_ELEMENT)
        if (reader.name == 'name' && reader.node.parent.name == 'realm')
          realm = reader.read_string
          realms << realm unless (realm.empty?)
        end
      end
    end
    return realms
  end

  def get_objects_for_role object_path, role_name
    objects = Set.new
    object_tag = object_path.split(/\//)
    object_tag = object_tag.last
    get_config_items(object_path, '', ['name', 'roles']) do |reader|
      matched = false
      while (reader.read)
        break if (reader.name == object_tag)
        next if (reader.node_type == XML::Reader::TYPE_END_ELEMENT)
        object_name = reader.read_string if (reader.name == 'name')
        if (reader.name == 'roles' && reader.read_string == role_name)
          matched = true
        end
      end
      objects << object_name if (matched && ! object_name.empty?)
    end
    return objects
  end

  def get_role_auth_tables role_name
    get_objects_for_role('configuration/uac/infranet-enforcer/auth-table-mapping-policies/auth-table-mapping-policy', role_name)
  end

  def get_role_address_pools role_name
    get_objects_for_role('configuration/uac/infranet-enforcer/ip-address-pools-policies/ip-address-pools-policy', role_name)
  end

  def get_role_ipsec_policies role_name
    get_objects_for_role('configuration/uac/infranet-enforcer/ipsec-routing-policies/ipsec-routing-policy', role_name)
  end

  def get_role_resources role_name
    get_objects_for_role('configuration/uac/infranet-enforcer/resource-access-policies/resource-access-policy', role_name)
  end

  def get_role_mappings role_name=nil
    mappings = {}
    get_realms.each do |realm_name|
      mappings[realm_name] = {}
      xml_string = build_xml('configuration/users/user-realms/realm') do |xml|
        xml.name realm_name
        build(xml, 'role-mapping-rules/rule') do
          xml.name
          xml.roles
        end
      end
      get_config_items('configuration/users/user-realms/realm/role-mapping-rules/rule', '', [], xml_string) do |reader|
        name = ""
        roles = Set.new
        while (reader.read)
          break if (reader.name == 'rule')
          next if (reader.node_type == XML::Reader::TYPE_END_ELEMENT)
          name = reader.read_string if (reader.name == 'name')
          if (reader.name == 'roles')
            matched_name = reader.read_string
            if (! matched_name.empty? && (role_name.nil? || role_name == matched_name))
              roles << matched_name
            end
          end
        end
        if (role_name.nil? || roles.size > 0)
          mappings[realm_name][name] = roles
        end
      end
    end
    mappings
  end

  def get_mapping_roles realm_name, mapping
    xml_string = build_xml('configuration/users/user-realms/realm') do |xml|
      xml.name realm_name
      build(xml, 'role-mapping-rules/rule') do 
        xml.name mapping
      end
    end
    roles = Set.new
    get_config_items('configuration/users/user-realms/realm/role-mapping-rules/rule', realm_name, [], xml_string) do |reader|
      while(reader.read)
        break if (reader.name == 'rule')
        next if (reader.node_type == XML::Reader::TYPE_END_ELEMENT)
        if (reader.name == 'roles')
          role = reader.read_string
          roles << role unless (role.empty?)
        end
      end
    end
    return roles
  end

  private
    def get_values reader, end_tag
      values = {}
      while (reader.read)
        break if (reader.name == end_tag)
        next if (reader.node_type == XML::Reader::TYPE_END_ELEMENT)
        if (values[reader.name])
          if (values[reader.name].is_a? String)
            s = Set.new
            s.add(values[reader.name])
           values[reader.name] = s
          end
          values[reader.name].add(reader.read_string)
        else
          values[reader.name] = reader.read_string
        end
      end
      values
    end

    def build_xml path, &block
      target = ""
      xml = Builder::XmlMarkup.new(:target => target, :indent => 1)
      build(xml, path, &block)
      target
    end

    def build xml, path, &block
      path = path.split(/\//) if (path.is_a? String)
      while true do
        if (path.length == 0)
          block.call xml
          return
        end
        element = path.shift
        unless (element.nil? || element == '')
          xml.tag! element do
            build xml, path, &block
          end
          return
        end
      end
      target
    end
 
    def get_config_items path, name, selectors=[], xml=nil, &block
      if (xml.nil?)
        xml = build_xml(path) do |xml|
          xml.name name unless (name == '')
          selectors.each do |selector|
            xml.tag! selector
          end
        end
      end

      path = path.split(/\//)
      current_path = []
      config = get_config('running', xml) do |reader|
        while (reader.read)
          break if (reader.name == 'data')
          current_path.push(reader.name) if (reader.node_type == XML::Reader::TYPE_ELEMENT)
          current_path.pop if (reader.node_type == XML::Reader::TYPE_END_ELEMENT)
          if (current_path == path)
            block.call(reader) if (block)
            current_path.pop
          end
        end
      end
    end
end

