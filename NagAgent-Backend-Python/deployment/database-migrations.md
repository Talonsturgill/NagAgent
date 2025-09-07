# Database Migration Guide for NagAgent

## Overview
This guide covers database schema management and migration processes for NagAgent using Alembic, the database migration tool for SQLAlchemy.

## Migration Workflow

### Development Process
1. **Make Model Changes** → Update SQLAlchemy models in `app/models.py`
2. **Generate Migration** → Create Alembic migration script
3. **Review Migration** → Manually verify the generated SQL
4. **Test Locally** → Apply migration to local database
5. **Commit Changes** → Add migration file to version control
6. **Deploy** → CI/CD pipeline applies migrations automatically

## Alembic Configuration

### Current Setup
```python
# alembic/env.py - Current configuration
import os
import sys
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context

# Add your model's MetaData object here
from app.database import Base
from app.models import *  # Import all models

target_metadata = Base.metadata

def run_migrations_offline():
    """Run migrations in 'offline' mode."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

def run_migrations_online():
    """Run migrations in 'online' mode."""
    configuration = config.get_section(config.config_ini_section)
    configuration["sqlalchemy.url"] = os.getenv("DATABASE_URL", "postgresql://localhost/nagagent")
    
    connectable = engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata
        )

        with context.begin_transaction():
            context.run_migrations()
```

### alembic.ini Configuration
```ini
# alembic.ini - Main configuration file
[alembic]
# Path to migration scripts
script_location = alembic

# Template used to generate migration files
file_template = %%(year)d%%(month).2d%%(day).2d_%%(hour).2d%%(minute).2d_%%(rev)s_%%(slug)s

# Timezone for new migration files
timezone = UTC

# Maximum number of characters to use for file names
truncate_slug_length = 40

# Database URL (overridden by environment variable)
sqlalchemy.url = postgresql://localhost:5432/nagagent

# Logging configuration
[loggers]
keys = root,sqlalchemy,alembic

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console
qualname =

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
```

## Migration Commands

### Development Workflow

#### 1. Generate New Migration
```bash
# After modifying models in app/models.py
alembic revision --autogenerate -m "Add user personality preferences"

# Manual migration (when autogenerate isn't sufficient)
alembic revision -m "Add custom indexes for performance"
```

#### 2. Review Generated Migration
```bash
# Check the latest migration file
ls -la alembic/versions/

# Review the migration content
cat alembic/versions/20240106_1430_abc123_add_user_personality_preferences.py
```

#### 3. Apply Migrations
```bash
# Apply all pending migrations
alembic upgrade head

# Apply specific migration
alembic upgrade abc123

# Apply one migration at a time
alembic upgrade +1

# Downgrade to previous version
alembic downgrade -1

# Downgrade to specific revision
alembic downgrade abc123

# Reset to base (empty database)
alembic downgrade base
```

#### 4. Check Migration Status
```bash
# Show current revision
alembic current

# Show migration history
alembic history

# Show pending migrations
alembic show head
```

### Production Deployment

#### Automated Migration (CI/CD)
```bash
# In GitHub Actions or Railway deployment
alembic upgrade head
```

#### Manual Production Migration
```bash
# Set production database URL
export DATABASE_URL="postgresql://user:pass@prod-host:5432/nagagent"

# Backup database first
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql

# Run migrations
alembic upgrade head

# Verify migration success
alembic current
```

## Migration Examples

### Example 1: Adding New Table
```python
# Migration file: 20240106_1430_001_add_user_preferences_table.py
"""Add user preferences table

Revision ID: 001
Revises: 
Create Date: 2024-01-06 14:30:00

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers
revision = '001'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    # Create user_preferences table
    op.create_table('user_preferences',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('personality_type', sa.String(50), nullable=False),
        sa.Column('notification_frequency', sa.String(20), nullable=False, server_default='daily'),
        sa.Column('timezone', sa.String(50), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.Index('ix_user_preferences_user_id', 'user_id'),
        sa.Index('ix_user_preferences_personality_type', 'personality_type')
    )

def downgrade():
    # Drop user_preferences table
    op.drop_table('user_preferences')
```

### Example 2: Adding Column
```python
# Migration file: 20240106_1500_002_add_voice_enabled_to_users.py
"""Add voice_enabled column to users

Revision ID: 002
Revises: 001
Create Date: 2024-01-06 15:00:00

"""
from alembic import op
import sqlalchemy as sa

revision = '002'
down_revision = '001'
branch_labels = None
depends_on = None

def upgrade():
    # Add voice_enabled column
    op.add_column('users', sa.Column('voice_enabled', sa.Boolean(), nullable=False, server_default=sa.false()))
    
    # Create index for better query performance
    op.create_index('ix_users_voice_enabled', 'users', ['voice_enabled'])

def downgrade():
    # Remove index first
    op.drop_index('ix_users_voice_enabled', 'users')
    
    # Remove column
    op.drop_column('users', 'voice_enabled')
```

### Example 3: Data Migration
```python
# Migration file: 20240106_1600_003_migrate_legacy_personality_data.py
"""Migrate legacy personality data

Revision ID: 003
Revises: 002
Create Date: 2024-01-06 16:00:00

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import table, column

revision = '003'
down_revision = '002'
branch_labels = None
depends_on = None

def upgrade():
    # Create a table representation for data migration
    users_table = table('users',
        column('id', sa.Integer),
        column('personality_old', sa.String),
        column('personality_type', sa.String)
    )
    
    # Migrate data from old column to new column
    connection = op.get_bind()
    
    # Update personality types
    personality_mapping = {
        'drill_sergeant': 'sergeant',
        'sassy_friend': 'sassy',
        'passive_aggressive': 'passive',
        'brutal_honest': 'brutal'
    }
    
    for old_type, new_type in personality_mapping.items():
        connection.execute(
            users_table.update()
            .where(users_table.c.personality_old == old_type)
            .values(personality_type=new_type)
        )
    
    # Drop old column
    op.drop_column('users', 'personality_old')

def downgrade():
    # Add back old column
    op.add_column('users', sa.Column('personality_old', sa.String(50)))
    
    # Reverse the data migration
    users_table = table('users',
        column('id', sa.Integer),
        column('personality_old', sa.String),
        column('personality_type', sa.String)
    )
    
    connection = op.get_bind()
    
    reverse_mapping = {
        'sergeant': 'drill_sergeant',
        'sassy': 'sassy_friend',
        'passive': 'passive_aggressive',
        'brutal': 'brutal_honest'
    }
    
    for new_type, old_type in reverse_mapping.items():
        connection.execute(
            users_table.update()
            .where(users_table.c.personality_type == new_type)
            .values(personality_old=old_type)
        )
```

## Migration Best Practices

### 1. Safe Migration Patterns

#### Adding Columns Safely
```python
def upgrade():
    # Always add columns as nullable first
    op.add_column('users', sa.Column('new_field', sa.String(100), nullable=True))
    
    # Then populate with default values if needed
    from sqlalchemy import text
    connection = op.get_bind()
    connection.execute(text("UPDATE users SET new_field = 'default_value' WHERE new_field IS NULL"))
    
    # Finally make it non-nullable if required
    op.alter_column('users', 'new_field', nullable=False)
```

#### Renaming Columns Safely
```python
def upgrade():
    # Step 1: Add new column
    op.add_column('users', sa.Column('new_name', sa.String(100), nullable=True))
    
    # Step 2: Copy data
    from sqlalchemy import text
    connection = op.get_bind()
    connection.execute(text("UPDATE users SET new_name = old_name"))
    
    # Step 3: Make new column non-nullable
    op.alter_column('users', 'new_name', nullable=False)
    
    # Step 4: Drop old column (in a separate migration)
    # op.drop_column('users', 'old_name')  # Do this in next migration
```

### 2. Performance Considerations

#### Creating Indexes Concurrently
```python
def upgrade():
    # For large tables, create indexes concurrently
    op.create_index(
        'ix_tasks_user_id_created_at',
        'tasks',
        ['user_id', 'created_at'],
        postgresql_concurrently=True
    )

def downgrade():
    op.drop_index('ix_tasks_user_id_created_at', 'tasks')
```

#### Batch Operations for Large Data
```python
def upgrade():
    connection = op.get_bind()
    
    # Process data in batches to avoid memory issues
    batch_size = 1000
    offset = 0
    
    while True:
        result = connection.execute(
            f"SELECT id FROM users WHERE needs_update = true "
            f"ORDER BY id OFFSET {offset} LIMIT {batch_size}"
        )
        
        rows = result.fetchall()
        if not rows:
            break
            
        user_ids = [row[0] for row in rows]
        connection.execute(
            f"UPDATE users SET updated_field = 'new_value' "
            f"WHERE id IN ({','.join(map(str, user_ids))})"
        )
        
        offset += batch_size
```

### 3. Testing Migrations

#### Migration Test Script
```python
# scripts/test_migration.py
import os
import subprocess
import tempfile
import shutil
from pathlib import Path

def test_migration_cycle():
    """Test migration up and down cycles"""
    
    # Create temporary database
    test_db_url = "postgresql://localhost:5432/nagagent_migration_test"
    
    try:
        # Create test database
        subprocess.run(["createdb", "nagagent_migration_test"], check=True)
        
        # Set database URL
        os.environ["DATABASE_URL"] = test_db_url
        
        # Get current revision
        current_rev = subprocess.run(
            ["alembic", "current"], 
            capture_output=True, text=True
        ).stdout.strip()
        
        # Downgrade to base
        subprocess.run(["alembic", "downgrade", "base"], check=True)
        
        # Upgrade to head
        subprocess.run(["alembic", "upgrade", "head"], check=True)
        
        # Verify we're back to current revision
        new_rev = subprocess.run(
            ["alembic", "current"], 
            capture_output=True, text=True
        ).stdout.strip()
        
        assert current_rev == new_rev, f"Migration test failed: {current_rev} != {new_rev}"
        
        print("✅ Migration test passed!")
        
    finally:
        # Cleanup test database
        subprocess.run(["dropdb", "nagagent_migration_test"], check=False)

if __name__ == "__main__":
    test_migration_cycle()
```

## Environment-Specific Migrations

### Development
```bash
# Use local database
export DATABASE_URL="postgresql://localhost:5432/nagagent_dev"
alembic upgrade head
```

### Staging
```bash
# Use staging database
export DATABASE_URL="$STAGING_DATABASE_URL"
alembic upgrade head
```

### Production
```bash
# Use production database with extra caution
export DATABASE_URL="$PRODUCTION_DATABASE_URL"

# Backup first
pg_dump $DATABASE_URL > production_backup_$(date +%Y%m%d_%H%M%S).sql

# Run migrations
alembic upgrade head
```

## Migration Troubleshooting

### Common Issues and Solutions

#### 1. Migration Conflicts
```bash
# When multiple developers create migrations simultaneously
alembic merge -m "Merge migrations" revision1 revision2
```

#### 2. Failed Migration Recovery
```bash
# If migration fails halfway
alembic stamp revision_before_failure
alembic upgrade head
```

#### 3. Rollback Production Migration
```bash
# Immediate rollback
alembic downgrade -1

# Rollback to specific version
alembic downgrade abc123

# If data needs to be preserved, create custom rollback migration
alembic revision -m "Rollback migration with data preservation"
```

#### 4. Schema Drift Detection
```bash
# Compare current database with models
alembic revision --autogenerate -m "Fix schema drift"
```

## Monitoring and Alerts

### Migration Monitoring Script
```python
# scripts/monitor_migrations.py
import subprocess
import json
import requests

def check_migration_status():
    """Check if database is up to date with migrations"""
    
    try:
        # Get current database revision
        current = subprocess.run(
            ["alembic", "current"], 
            capture_output=True, text=True
        ).stdout.strip()
        
        # Get head revision
        head = subprocess.run(
            ["alembic", "show", "head"], 
            capture_output=True, text=True
        ).stdout.split()[0]
        
        if current != head:
            alert_data = {
                "text": f"⚠️ Database migration out of sync! Current: {current}, Head: {head}",
                "channel": "#alerts"
            }
            
            # Send to Slack (replace with your webhook URL)
            requests.post(
                "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK",
                json=alert_data
            )
            
            return False
        
        return True
        
    except Exception as e:
        print(f"Error checking migration status: {e}")
        return False

if __name__ == "__main__":
    check_migration_status()
```

## Migration Checklist

### Before Creating Migration
- [ ] Models are properly defined and tested
- [ ] Migration purpose is clear and documented
- [ ] Breaking changes are avoided when possible
- [ ] Performance impact is considered

### Creating Migration
- [ ] Use descriptive migration message
- [ ] Review autogenerated migration code
- [ ] Add manual changes if autogenerate missed anything
- [ ] Test migration locally

### Before Deploying
- [ ] Migration is tested in staging environment
- [ ] Database backup is available
- [ ] Downgrade strategy is prepared
- [ ] Team is notified of deployment

### After Deployment
- [ ] Migration completed successfully
- [ ] Application is working correctly
- [ ] Performance metrics are normal
- [ ] No errors in application logs

---

**Remember**: Migrations are permanent changes to your database structure. Always test thoroughly and have a rollback plan before deploying to production.