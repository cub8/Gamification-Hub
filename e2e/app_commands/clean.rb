# frozen_string_literal: true

# Run before every test: empties all tables and the outbox, so tests do not see each other's data.
connection = ActiveRecord::Base.connection
kept = [ActiveRecord::Base.schema_migrations_table_name, ActiveRecord::Base.internal_metadata_table_name]
tables = (connection.tables - kept).map { connection.quote_table_name(it) }
connection.execute("TRUNCATE #{tables.join(', ')} RESTART IDENTITY CASCADE")

ActionMailer::Base.deliveries.clear
CypressOnRails::SmartFactoryWrapper.reload
