---
name: openmage-module-developer
description: Build a new custom module for this OpenMage 1.x LMS, in the MMD vendor namespace under app/code/local/MMD/. Use when the user asks to create a new admin feature, scaffold a module, add a custom controller/model/block, wire an event observer, or add a class rewrite. Tailored to this repo's conventions (no Setup/Install scripts — use migrations/NNN-*.sql; MMD_ prefix; existing modules like RoleManager, Courses, BankPayment as reference patterns).
---

# OpenMage Module Developer (Tertiary Courses LMS)

You are building a new module in `app/code/local/MMD/<ModuleName>/` for OpenMage 1.x on PHP 8.2. **Not Magento 2.**

## Reference modules already in this repo

Read these before scaffolding — they show the real conventions:

| Module | What to learn from it |
|--------|----------------------|
| `app/code/local/MMD/RoleManager/` | Observer pattern, custom admin controllers (Roleswitch, Roleselect, Rolemanagement), helper with business logic, ACL group manipulation, custom DB table (`mmd_user_role_map`) |
| `app/code/local/MMD/EmailLogin/` | Class rewrite via `<rewrite>` in config.xml (rewrites `admin/user` to support email login) |
| `app/code/local/MMD/Courses/` | Admin grid + form CRUD, export, custom admin layout XML |
| `app/code/local/MMD/BankPayment/` | Custom payment method, system.xml configuration block, admin config form |
| `app/code/local/MMD/CustomOptions/` | Product option enhancements, multi-version SKU policies |

When asked "how do I do X", first check if an existing MMD module already does something analogous. Don't reinvent.

## Minimum viable module — 4 files

For a no-op module (just to register and be enabled):

```
app/etc/modules/MMD_Foo.xml                          # registration
app/code/local/MMD/Foo/etc/config.xml                # config
app/code/local/MMD/Foo/Helper/Data.php               # required for Mage::helper('mmd_foo')
app/code/local/MMD/Foo/etc/system.xml                # only if adding admin config
```

### `app/etc/modules/MMD_Foo.xml`

```xml
<?xml version="1.0"?>
<config>
    <modules>
        <MMD_Foo>
            <active>true</active>
            <codePool>local</codePool>
            <depends>
                <Mage_Core/>
            </depends>
        </MMD_Foo>
    </modules>
</config>
```

Naming rule: `MMD_<ModuleName>` (Studly). Always `codePool=local`. List explicit `<depends>` — at least `Mage_Core`; add `Mage_Adminhtml` if the module has admin UI; add `MMD_RoleManager` if it uses role helpers.

### `app/code/local/MMD/Foo/etc/config.xml`

```xml
<?xml version="1.0"?>
<config>
    <modules>
        <MMD_Foo>
            <version>1.0.0</version>
        </MMD_Foo>
    </modules>

    <global>
        <helpers>
            <mmd_foo>
                <class>MMD_Foo_Helper</class>
            </mmd_foo>
        </helpers>
        <models>
            <mmd_foo>
                <class>MMD_Foo_Model</class>
                <resourceModel>mmd_foo_resource</resourceModel>
            </mmd_foo>
            <mmd_foo_resource>
                <class>MMD_Foo_Model_Resource</class>
                <entities>
                    <thing>
                        <table>mmd_foo_thing</table>
                    </thing>
                </entities>
            </mmd_foo_resource>
        </models>
        <blocks>
            <mmd_foo>
                <class>MMD_Foo_Block</class>
            </mmd_foo>
        </blocks>
        <events>
            <controller_action_predispatch>
                <observers>
                    <mmd_foo_predispatch>
                        <class>mmd_foo/observer</class>
                        <method>onPredispatch</method>
                    </mmd_foo_predispatch>
                </observers>
            </controller_action_predispatch>
        </events>
    </global>

    <adminhtml>
        <menu>
            <mmd>
                <title>MMD</title>
                <sort_order>100</sort_order>
                <children>
                    <foo translate="title" module="mmd_foo">
                        <title>Foo Management</title>
                        <action>adminhtml/foo</action>
                        <sort_order>10</sort_order>
                    </foo>
                </children>
            </mmd>
        </menu>
        <acl>
            <resources>
                <admin>
                    <children>
                        <mmd>
                            <title>MMD</title>
                            <children>
                                <foo translate="title" module="mmd_foo">
                                    <title>Foo</title>
                                </foo>
                            </children>
                        </mmd>
                    </children>
                </admin>
            </resources>
        </acl>
    </adminhtml>

    <admin>
        <routers>
            <adminhtml>
                <args>
                    <modules>
                        <mmd_foo before="Mage_Adminhtml">MMD_Foo_Adminhtml</mmd_foo>
                    </modules>
                </args>
            </adminhtml>
        </routers>
    </admin>
</config>
```

Key points:
- Aliases (`mmd_foo`) are lowercase, underscore-separated. Reused as `Mage::helper('mmd_foo')`, `Mage::getModel('mmd_foo/thing')`, etc.
- `<table>` is the actual MySQL table name. Match it to the alias by convention.
- Admin controllers go under `<admin><routers>` with `before="Mage_Adminhtml"` so admin routes map to your module's `controllers/Adminhtml/*Controller.php`.
- ACL nodes must match the menu nodes. Match exactly or the menu item shows up but every click is denied.

### `app/code/local/MMD/Foo/Helper/Data.php`

```php
<?php
class MMD_Foo_Helper_Data extends Mage_Core_Helper_Abstract
{
    public function getThing()
    {
        return 'thing';
    }
}
```

A Helper is mandatory — `Mage::helper('mmd_foo')` is how the admin menu's `module="mmd_foo"` translation hook resolves. Without a Helper, the menu title appears as the raw key.

## Adding a custom DB table — use `migrations/NNN-*.sql`

**Do not create `app/code/local/MMD/Foo/sql/mmd_foo_setup/mysql4-install-1.0.0.php`.** This project doesn't use Magento's install/upgrade scripts.

Instead, add a migration:

```sql
-- migrations/NNN-mmd-foo-thing-table.sql

CREATE TABLE IF NOT EXISTS `mmd_foo_thing` (
    `thing_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(255) NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`thing_id`),
    KEY `IDX_NAME` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

Apply locally:

```bash
docker exec ai-mms-web-1 php /var/www/html/migrations/apply.php
```

## Models & resource models

```php
// app/code/local/MMD/Foo/Model/Thing.php
class MMD_Foo_Model_Thing extends Mage_Core_Model_Abstract
{
    protected function _construct() { $this->_init('mmd_foo/thing'); }
}

// app/code/local/MMD/Foo/Model/Resource/Thing.php
class MMD_Foo_Model_Resource_Thing extends Mage_Core_Model_Resource_Db_Abstract
{
    protected function _construct() { $this->_init('mmd_foo/thing', 'thing_id'); }
}

// app/code/local/MMD/Foo/Model/Resource/Thing/Collection.php
class MMD_Foo_Model_Resource_Thing_Collection extends Mage_Core_Model_Resource_Db_Collection_Abstract
{
    protected function _construct() { $this->_init('mmd_foo/thing'); }
}
```

Usage:
```php
$thing = Mage::getModel('mmd_foo/thing');
$thing->load(42);
$thing->setData('name', 'X')->save();
$collection = Mage::getModel('mmd_foo/thing')->getCollection()->addFieldToFilter('name', 'X');
```

## Admin controllers

```php
class MMD_Foo_Adminhtml_FooController extends Mage_Adminhtml_Controller_Action
{
    protected function _isAllowed()
    {
        return Mage::getSingleton('admin/session')->isAllowed('admin/mmd/foo');
    }

    public function indexAction()
    {
        $this->loadLayout()
             ->_setActiveMenu('mmd/foo')
             ->_title($this->__('MMD'))->_title($this->__('Foo Management'));
        $this->renderLayout();
    }

    public function saveAction()
    {
        $this->_validateFormKey();
        $this->_redirect('*/*/');
    }
}
```

Always implement `_isAllowed()` — Magento 1 default denies. Resource path must match the `<acl>` tree in config.xml exactly.

## Event observers

```xml
<global>
    <events>
        <sales_order_place_after>
            <observers>
                <mmd_foo_order_place>
                    <class>mmd_foo/observer</class>
                    <method>onOrderPlace</method>
                </mmd_foo_order_place>
            </observers>
        </sales_order_place_after>
    </events>
</global>
```

```php
class MMD_Foo_Model_Observer
{
    public function onOrderPlace(Varien_Event_Observer $observer)
    {
        try {
            $order = $observer->getEvent()->getOrder();
            // ...
        } catch (Exception $e) {
            Mage::logException($e);
        }
    }
}
```

**Always wrap observer bodies in try/catch.** An uncaught exception in `controller_action_predispatch` hard-fails every request. `Mage::logException` then return silently.

## Class rewrites (extending core)

Prefer this over copying entire core classes to `app/code/local/Mage/...`.

```xml
<global>
    <models>
        <admin>
            <rewrite>
                <user>MMD_Foo_Model_Admin_User</user>
            </rewrite>
        </admin>
    </models>
</global>
```

```php
class MMD_Foo_Model_Admin_User extends Mage_Admin_Model_User { /* override */ }
```

See `app/code/local/MMD/EmailLogin/etc/config.xml` for the canonical example.

## Country-aware code

```php
$cc        = Mage::helper('mmd_rolemanager')->getActiveCountryCode();    // 'SG'|'MY'|'GH'|'NG'|'BT'|'IN'
$websiteId = Mage::helper('mmd_rolemanager')->getActiveWebsiteId();      // 1..6
```

Use these to filter views/queries by the admin user's country instead of leaking cross-country data.

## Role-aware controllers

Use `MMD_RoleManager_Helper_Data::isRoleAllowed(['admin', 'training_provider'])` for fine-grained gating beyond standard ACL. If your new admin controller should be role-restricted, add its `<module>_<controller>` key into `_roleControllerMap()` in `app/code/local/MMD/RoleManager/Model/Observer.php`.

## After scaffolding

1. Clear cache: `docker exec ai-mms-web-1 sh -c 'rm -rf /var/www/html/var/cache/*'`
2. Visit `http://localhost:8080/tigerdragon/<your_route>/` and confirm:
   - Menu item appears.
   - Click loads without "Access denied" (if so → ACL mismatch).
   - Click loads without "Page not found" (if so → admin router block missing).
3. Run the `openmage-code-reviewer` skill on the new files.

## Don't

- Don't use `app/code/local/<Vendor>/Foo/sql/...mysql4-install...php`. Use `migrations/NNN-*.sql`.
- Don't create the module under `app/code/community/`. Always `app/code/local/MMD/`.
- Don't skip the Helper class. Even an empty `Helper/Data.php` is required.
- Don't add features to `Mage_Adminhtml` core controllers — make a new admin controller in your module.
- Don't depend on Magento 2 concepts (DI, service contracts, repositories, declare(strict_types)). OpenMage 1.x idioms only.
- Don't forget `_validateFormKey()` on POST/save/delete.
- Don't catch exceptions silently. Log + addError + redirect, or log + return JSON for AJAX.

## Related

- **openmage-code-reviewer** — review before commit.
- **mysql** — for table schema and migration patterns.
- **add-country-store** — if module touches multi-country logic.
