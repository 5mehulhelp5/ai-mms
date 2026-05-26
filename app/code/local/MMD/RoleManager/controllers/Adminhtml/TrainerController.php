<?php
class MMD_RoleManager_Adminhtml_TrainerController extends Mage_Adminhtml_Controller_Action
{
    /**
     * Skip form-key validation for AJAX actions (the admin URL secret key
     * already provides CSRF protection).
     */
    protected function _validateFormKey()
    {
        return true;
    }

    /**
     * Expects POST: email, full_name, status (1|0), telephone, trainer_type,
     * gender, linkedin_url, default_password (informational only).
     * Returns JSON: { success: bool, message: string, trainer_id?: int }
     */
    public function addAction()
    {
        $result = array('success' => false);

        try {
            if (!$this->getRequest()->isPost()) {
                $result['message'] = 'POST required';
                $this->_sendJson($result);
                return;
            }

            $email    = trim((string) $this->getRequest()->getPost('email'));
            $name     = trim((string) $this->getRequest()->getPost('full_name'));
            $statusIn = (string) $this->getRequest()->getPost('status');
            $tel      = trim((string) $this->getRequest()->getPost('telephone'));
            $type     = trim((string) $this->getRequest()->getPost('trainer_type'));
            $gender   = trim((string) $this->getRequest()->getPost('gender'));
            $linkedin = trim((string) $this->getRequest()->getPost('linkedin_url'));
            $description = (string) $this->getRequest()->getPost('description');

            // Only Full Name is required. Everything else is optional; sensible
            // defaults are applied below (status=Active when not chosen).
            if ($name === '') {
                $result['message'] = 'Full Name is required';
                $this->_sendJson($result);
                return;
            }
            if ($email !== '' && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
                $result['message'] = 'Invalid email address';
                $this->_sendJson($result);
                return;
            }

            $resource = Mage::getSingleton('core/resource');
            $write    = $resource->getConnection('core_write');
            $table    = $resource->getTableName('courses_trainers');

            // Reject duplicate email only when an email was actually provided.
            if ($email !== '') {
                $exists = $write->fetchOne("SELECT trainers_id FROM {$table} WHERE email = ?", array($email));
                if ($exists) {
                    $result['message'] = 'A trainer with that email already exists';
                    $this->_sendJson($result);
                    return;
                }
            }

            // Detect optional columns so we save into them only if they exist
            // (keeps the action portable across schema variants — local lacks
            // telephone/trainer_type/gender/linkedin_url, prod may have them).
            $cols = $write->fetchCol("SHOW COLUMNS FROM {$table}");
            $colSet = array_flip($cols);

            // Default status = Active (1) when the admin didn't pick one.
            $statusVal = ($statusIn === 'Inactive' || $statusIn === '0') ? 0 : 1;
            $row = array(
                'title'         => $name,
                'email'         => $email,
                'profile_image' => '',
                'status'        => $statusVal,
                'created_time'  => date('Y-m-d H:i:s'),
                'update_time'   => date('Y-m-d H:i:s'),
            );
            if (isset($colSet['relation_id'])) $row['relation_id'] = 0;
            if (isset($colSet['telephone']))   $row['telephone']   = $tel;
            if (isset($colSet['tel']))         $row['tel']         = $tel;
            if (isset($colSet['phone']))       $row['phone']       = $tel;
            if (isset($colSet['trainer_type']))$row['trainer_type']= $type;
            if (isset($colSet['type']))        $row['type']        = $type;
            if (isset($colSet['gender']))      $row['gender']      = $gender;
            if (isset($colSet['linkedin_url']))$row['linkedin_url']= $linkedin;
            if (isset($colSet['linkedin']))    $row['linkedin']    = $linkedin;
            if (isset($colSet['description'])) $row['description'] = $description !== '' ? $description : null;

            $write->insert($table, $row);
            $newId = (int) $write->lastInsertId($table);

            $result['success']    = true;
            $result['trainer_id'] = $newId;
            $result['message']    = 'Trainer added successfully';
        } catch (Exception $e) {
            $result['message'] = 'Error: ' . $e->getMessage();
        } catch (Error $e) {
            $result['message'] = 'Error: ' . $e->getMessage();
        }

        $this->_sendJson($result);
    }

    /**
     * AJAX action — update an existing trainer.
     */
    public function editAction()
    {
        $result = array('success' => false);

        try {
            if (!$this->getRequest()->isPost()) {
                $result['message'] = 'POST required';
                $this->_sendJson($result);
                return;
            }

            $trainerId = (int) $this->getRequest()->getPost('trainer_id');
            if (!$trainerId) {
                $result['message'] = 'Trainer ID is required';
                $this->_sendJson($result);
                return;
            }

            // Edit mode: every field is optional. A blank submission means
            // "leave the existing value alone" — we only write fields the
            // admin actually filled in, so accidental blanks don't overwrite
            // good data. Required-field validation lives in addAction; edit
            // assumes the row was already valid when it was created.
            $email    = trim((string) $this->getRequest()->getPost('email'));
            $name     = trim((string) $this->getRequest()->getPost('full_name'));
            $tel      = trim((string) $this->getRequest()->getPost('telephone'));
            $type     = trim((string) $this->getRequest()->getPost('trainer_type'));
            $statusIn = (string) $this->getRequest()->getPost('status');
            $gender   = trim((string) $this->getRequest()->getPost('gender'));
            $linkedin = trim((string) $this->getRequest()->getPost('linkedin_url'));
            $description = (string) $this->getRequest()->getPost('description');

            $resource = Mage::getSingleton('core/resource');
            $write    = $resource->getConnection('core_write');
            $table    = $resource->getTableName('courses_trainers');
            $cols     = array_flip($write->fetchCol("SHOW COLUMNS FROM {$table}"));

            $row = array('update_time' => date('Y-m-d H:i:s'));
            if ($name  !== '') $row['title'] = $name;
            if ($email !== '') $row['email'] = $email;
            // Status select is always present in the POST when the form is
            // submitted, so update only when the admin chose something explicit.
            if ($statusIn === 'Active' || $statusIn === '1')   $row['status'] = 1;
            elseif ($statusIn === 'Inactive' || $statusIn === '0') $row['status'] = 0;
            if ($tel  !== '' && isset($cols['telephone']))    $row['telephone']    = $tel;
            if ($type !== '' && isset($cols['trainer_type'])) $row['trainer_type'] = $type;
            if ($gender !== '' && isset($cols['gender']))     $row['gender']       = $gender;
            if ($linkedin !== '' && isset($cols['linkedin_url'])) $row['linkedin_url'] = $linkedin;
            // Description is the one field where a blank submission *is*
            // meaningful (clearing the bio is a normal edit), so always write it.
            if (isset($cols['description']))  $row['description']  = $description !== '' ? $description : null;

            $write->update($table, $row, array('trainers_id = ?' => $trainerId));

            // Mirror the description into admin_user.trainer_description for
            // the matching admin user, so the trainer-role user sees the
            // latest text on their My Profile page (the two columns are
            // kept as bidirectional siblings — see profile.phtml and the
            // AccountController's saveAction which writes in the other
            // direction). Silent no-op if no matching admin_user exists.
            // Use whatever email actually lives on the trainer row now —
            // the admin may have submitted a blank email (= no change),
            // in which case the row's existing email is what we want to
            // match against admin_user.email.
            try {
                $mirrorEmail = $email !== '' ? $email : (string) $write->fetchOne(
                    "SELECT email FROM {$table} WHERE trainers_id = ?",
                    [$trainerId]
                );
                if ($mirrorEmail !== '') {
                    $auTable = $resource->getTableName('admin/user');
                    $auCols  = array_flip($write->fetchCol("SHOW COLUMNS FROM {$auTable}"));
                    if (isset($auCols['trainer_description'])) {
                        $write->update(
                            $auTable,
                            ['trainer_description' => $description !== '' ? $description : null],
                            ['email = ?' => $mirrorEmail]
                        );
                    }
                }
            } catch (Exception $_mirrEx) {
                Mage::logException($_mirrEx);
            }

            $result['success'] = true;
            $result['message'] = 'Trainer updated successfully';
        } catch (Exception $e) {
            $result['message'] = 'Error: ' . $e->getMessage();
        }

        $this->_sendJson($result);
    }

    /**
     * AJAX action — delete a trainer.
     */
    public function deleteAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) {
                $result['message'] = 'POST required';
                $this->_sendJson($result);
                return;
            }
            $trainerId = (int) $this->getRequest()->getPost('trainer_id');
            if (!$trainerId) {
                $result['message'] = 'Trainer ID is required';
                $this->_sendJson($result);
                return;
            }
            $resource = Mage::getSingleton('core/resource');
            $write    = $resource->getConnection('core_write');
            $table    = $resource->getTableName('courses_trainers');
            $write->delete($table, array('trainers_id = ?' => $trainerId));
            $result['success'] = true;
            $result['message'] = 'Trainer deleted';
        } catch (Exception $e) {
            $result['message'] = 'Error: ' . $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * AJAX action — toggle trainer active/inactive status.
     */
    public function toggleStatusAction()
    {
        $result = array('success' => false);
        try {
            if (!$this->getRequest()->isPost()) {
                $result['message'] = 'POST required';
                $this->_sendJson($result);
                return;
            }
            $trainerId = (int) $this->getRequest()->getPost('trainer_id');
            if (!$trainerId) {
                $result['message'] = 'Trainer ID is required';
                $this->_sendJson($result);
                return;
            }
            $resource = Mage::getSingleton('core/resource');
            $write    = $resource->getConnection('core_write');
            $table    = $resource->getTableName('courses_trainers');
            $current  = (int) $write->fetchOne("SELECT status FROM {$table} WHERE trainers_id = ?", array($trainerId));
            $newStatus = ($current === 1) ? 0 : 1;
            $write->update($table, array('status' => $newStatus, 'update_time' => date('Y-m-d H:i:s')), array('trainers_id = ?' => $trainerId));
            $result['success']    = true;
            $result['new_status'] = $newStatus;
            $result['message']    = $newStatus ? 'Trainer activated' : 'Trainer deactivated';
        } catch (Exception $e) {
            $result['message'] = 'Error: ' . $e->getMessage();
        }
        $this->_sendJson($result);
    }

    /**
     * Stream a CSV template with the bulk-upload columns.
     */
    public function templateAction()
    {
        $headers = array(
            'Common Name', 'Full Name', 'Country', 'Domain', 'Contact',
            'Email', 'CN Plus Email', 'ACLP', 'LinkedIn', 'CV', 'NRIC'
        );
        $sample = array(
            'JaneD', 'Jane Doe', 'Singapore', 'IT', '+65 8123 4567',
            'jane.doe@example.com', '', 'TRUE', 'https://linkedin.com/in/janedoe', '', 'S1234567A'
        );

        $this->getResponse()
            ->setHeader('Content-Type', 'text/csv; charset=utf-8', true)
            ->setHeader('Content-Disposition', 'attachment; filename="trainers-template.csv"', true);

        $body  = implode(',', $headers) . "\r\n";
        $body .= '"' . implode('","', $sample) . '"' . "\r\n";
        $this->getResponse()->setBody($body);
    }

    /**
     * Bulk-upload trainers from a CSV file.
     * POST: file (multipart upload), form_key.
     * Returns JSON: { success, created, updated, errors:[{row, message}] }
     */
    public function bulkUploadAction()
    {
        $result = array('success' => false, 'created' => 0, 'updated' => 0, 'errors' => array());

        try {
            if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
                $result['errors'][] = array('row' => 0, 'message' => 'No file uploaded');
                $this->_sendJson($result);
                return;
            }

            $tmp  = $_FILES['file']['tmp_name'];
            $name = strtolower($_FILES['file']['name']);
            $ext  = pathinfo($name, PATHINFO_EXTENSION);

            if (!in_array($ext, array('csv'))) {
                $result['errors'][] = array('row' => 0, 'message' => 'Only CSV files are supported in this build (xlsx/xls coming later)');
                $this->_sendJson($result);
                return;
            }

            $fh = fopen($tmp, 'r');
            if (!$fh) {
                $result['errors'][] = array('row' => 0, 'message' => 'Could not read uploaded file');
                $this->_sendJson($result);
                return;
            }

            $header = fgetcsv($fh);
            if (!$header) {
                $result['errors'][] = array('row' => 0, 'message' => 'Empty file');
                fclose($fh);
                $this->_sendJson($result);
                return;
            }
            // Normalize header → lowercased keys
            $idx = array();
            foreach ($header as $i => $h) {
                $key = strtolower(trim($h));
                $idx[$key] = $i;
            }
            $get = function ($row, $key) use ($idx) {
                if (!isset($idx[$key])) return '';
                $i = $idx[$key];
                return isset($row[$i]) ? trim($row[$i]) : '';
            };

            $resource = Mage::getSingleton('core/resource');
            $write    = $resource->getConnection('core_write');
            $table    = $resource->getTableName('courses_trainers');
            $cols     = array_flip($write->fetchCol("SHOW COLUMNS FROM {$table}"));

            // First pass: dedupe the CSV by email (case-insensitive, last occurrence wins).
            // Also validates each row and collects errors.
            $byEmail = array();   // lower(email) => parsed row
            $rowNum  = 1;
            while (($r = fgetcsv($fh)) !== false) {
                $rowNum++;
                if (count(array_filter($r, 'strlen')) === 0) continue; // skip blank rows

                $email = $get($r, 'email');
                $name  = $get($r, 'full name');

                if ($email === '' || $name === '') {
                    $result['errors'][] = array('row' => $rowNum, 'message' => 'Full Name and Email are required');
                    continue;
                }
                if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                    $result['errors'][] = array('row' => $rowNum, 'message' => 'Invalid email: ' . $email);
                    continue;
                }

                $aclpRaw = strtoupper($get($r, 'aclp'));
                $type    = ($aclpRaw === 'TRUE' || $aclpRaw === '1' || $aclpRaw === 'YES') ? 'ACLP' : 'non-ACLP';

                $row = array(
                    'title'         => $name,
                    'email'         => $email,
                    'profile_image' => '',
                    'status'        => 1,
                    'update_time'   => date('Y-m-d H:i:s'),
                );
                if (isset($cols['relation_id']))   $row['relation_id']  = 0;
                if (isset($cols['country_id']))    $row['country_id']   = $get($r, 'country');
                if (isset($cols['telephone']))     $row['telephone']    = $get($r, 'contact');
                if (isset($cols['trainer_type']))  $row['trainer_type'] = $type;
                if (isset($cols['linkedin_url']))  $row['linkedin_url'] = $get($r, 'linkedin');
                if (isset($cols['gender']))        $row['gender']       = 'Prefer not to say';

                // Last occurrence of a given email wins — later rows overwrite earlier
                $byEmail[strtolower($email)] = $row;
            }
            fclose($fh);

            // Second pass: write deduped rows to DB (insert or update by email)
            $result['skipped_duplicates'] = 0;
            foreach ($byEmail as $row) {
                $existingId = $write->fetchOne("SELECT trainers_id FROM {$table} WHERE email = ?", array($row['email']));
                if ($existingId) {
                    $write->update($table, $row, array('trainers_id = ?' => (int)$existingId));
                    $result['updated']++;
                } else {
                    $row['created_time'] = date('Y-m-d H:i:s');
                    $write->insert($table, $row);
                    $result['created']++;
                }
            }
            $result['success'] = true;
        } catch (Exception $e) {
            $result['errors'][] = array('row' => 0, 'message' => 'Error: ' . $e->getMessage());
        } catch (Error $e) {
            $result['errors'][] = array('row' => 0, 'message' => 'Error: ' . $e->getMessage());
        }

        $this->_sendJson($result);
    }

    protected function _isAllowed()
    {
        return Mage::helper('mmd_rolemanager')->isRoleAllowed(array(
            'training_provider', 'admin',
        ));
    }

    protected function _sendJson(array $data)
    {
        $this->getResponse()
            ->setHeader('Content-Type', 'application/json', true)
            ->setBody(Mage::helper('core')->jsonEncode($data));
    }
}
