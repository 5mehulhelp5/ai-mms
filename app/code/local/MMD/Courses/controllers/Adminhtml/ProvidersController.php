<?php

class MMD_Courses_Adminhtml_ProvidersController extends Mage_Adminhtml_Controller_Action
{

	
	public function indexAction()
    {
        
        $this->loadLayout();

        /**
         * Set active menu item
         */
        $this->_setActiveMenu('courses/providers');

        /**
         * Append customers block to content
         */
        $this->_addContent(
            $this->getLayout()->createBlock('courses/adminhtml_providers')
        );

        $this->renderLayout();
    }
	public function getstateAction() {
		$countrycode = $this->getRequest()->getParam('country');
		
			if ($countrycode != '') {
				$statearray = Mage::getModel('directory/region')->getResourceCollection()->addCountryFilter($countrycode)->load();
				
				if(count($statearray)>0){
					$state = "<option value=''>Please Select</option>";
					foreach ($statearray as $_state) {
					$state .= "<option value='" . $_state->getCode() . "'>" . $_state->getDefaultName() . "</option>";
					}
				}
				else{
					echo 'nostates';	
				}
			}
		echo $state;
		exit;
	}
	public function editAction() {
		$id     = $this->getRequest()->getParam('id');
		$model  = Mage::getModel('courses/providers')->load($id);
		if ($model->getId() || $id == 0) {
			
			$data = Mage::getSingleton('adminhtml/session')->getFormData(true);
			if (!empty($data)) {
				$model->setData($data);
			}

			Mage::register('providers_data', $model);

			
			$this->loadLayout();
			$this->_setActiveMenu('courses/providers');
			
			$this->getLayout()->getBlock('head')->setCanLoadExtJs(true);

			$this->_addContent($this->getLayout()->createBlock('courses/adminhtml_providers_edit'))
				->_addLeft($this->getLayout()->createBlock('courses/adminhtml_providers_edit_tabs'));

			$this->renderLayout();
		} else {
			Mage::getSingleton('adminhtml/session')->addError(Mage::helper('courses')->__('Item does not exist'));
			$this->_redirect('*/*/');
		}
	}
 
	public function newAction() {
		$this->_forward('edit');
	}
 
	public function saveAction() {
		if ($data = $this->getRequest()->getPost()) {

			// Snapshot the trainer's OLD email BEFORE the save runs.
			// Drives the reverse sync into admin_user below: if the
			// editor changed the email, we still need to find the
			// matching admin_user row by the previous value.
			$_oldTrainerEmail = '';
			$_postedId = (int) $this->getRequest()->getParam('id');
			if ($_postedId > 0) {
				try {
					$_resourceSnap = Mage::getSingleton('core/resource');
					$_oldTrainerEmail = strtolower((string) $_resourceSnap->getConnection('core_read')->fetchOne(
						'SELECT email FROM ' . $_resourceSnap->getTableName('courses_trainers')
						. ' WHERE trainers_id = ?',
						array($_postedId)
					));
				} catch (Exception $_snapEx) {
					Mage::logException($_snapEx);
				}
			}

			if(isset($_FILES['profile_image']['name']) && $_FILES['profile_image']['name'] != '') {
				try {	
					/* Starting upload */	
					$filename = str_replace(" ", "_", time().'_'.$_FILES['profile_image']['name']);
					/* Starting upload */	
					$uploader = new Varien_File_Uploader('profile_image');
					
					// Any extention would work
	           		$uploader->setAllowedExtensions(array('jpg','jpeg','gif','png'));
					$uploader->setAllowRenameFiles(false);
					
					// Set the file upload mode 
					// false -> get the file directly in the specified folder
					// true -> get the file in the product like folders 
					//	(file.jpg will go in something like /media/f/i/file.jpg)
					$uploader->setFilesDispersion(false);
							
					// We set media as the upload dir
					$path = Mage::getBaseDir('media') . DS . 'providers' . DS;
					$uploader->save($path, $filename);
					
				} catch (Exception $e) {
		      
		        }
	        
		        //this way the name is saved in DB
	  			$data['profile_image'] = 'providers/'.$filename;
				
				
				
			} else {
			
			if(isset($data['profile_image']['delete']) && $data['profile_image']['delete'] == 1) {
					 $data['profile_image'] = '';
				} else {
					unset($data['profile_image']);
				}	
			}
	  		
			if(isset($data['region']) && $data['region']!=''){
				
				$data['region_id']='';
			}
			elseif(isset($data['region_id']) && $data['region_id']!=''){
				$data['region']='';
			}
	  			
			$model = Mage::getModel('courses/providers');		
			$model->setData($data)
				->setId($this->getRequest()->getParam('id'));
			
			try {
				if ($model->getCreatedTime == NULL || $model->getUpdateTime() == NULL) {
					$model->setCreatedTime(now())
						->setUpdateTime(now());
				} else {
					$model->setUpdateTime(now());
				}	
				
				$model->save();

				// Reverse sync: mirror shared columns from the saved
				// courses_trainers row back into admin_user, matched by
				// email. Keeps My Profile in sync with edits made on
				// the View Trainers grid. Skips fields with no
				// admin_user equivalent (status, area_of_expertise,
				// trainer_type, region, address, etc.) and skips
				// profile_image (path scheme differs — admin uploads
				// land in /media/admin/profile/, trainer uploads in
				// /media/providers/). Best-effort: a stale admin_user
				// schema or an email that matches no admin must not
				// fail the trainer save.
				try {
					$_resSync   = Mage::getSingleton('core/resource');
					$_writeSync = $_resSync->getConnection('core_write');
					$_newTrainerEmail = strtolower((string) $model->getEmail());
					$_lookupEmail     = $_newTrainerEmail !== ''
						? $_newTrainerEmail
						: $_oldTrainerEmail;

					if ($_lookupEmail !== '') {
						$_userSync = array();

						// title → firstname + lastname. Split on the
						// first whitespace so "Evan Pang Wei Ming"
						// becomes firstname="Evan", lastname="Pang
						// Wei Ming" (matches how Magento splits names
						// elsewhere). Skip the field if title is
						// empty so we don't blank the user's name.
						$_title = trim((string) $model->getTitle());
						if ($_title !== '') {
							$_parts = preg_split('/\s+/', $_title, 2);
							$_userSync['firstname'] = $_parts[0];
							$_userSync['lastname']  = isset($_parts[1]) ? $_parts[1] : '';
						}

						$_telSync = (string) $model->getTelephone();
						if ($_telSync !== '' || array_key_exists('telephone', $data)) {
							$_userSync['tel'] = $_telSync !== '' ? $_telSync : null;
						}
						$_genderSync = (string) $model->getGender();
						if ($_genderSync !== '' || array_key_exists('gender', $data)) {
							$_userSync['gender'] = $_genderSync !== '' ? $_genderSync : null;
						}
						$_linkedinSync = (string) $model->getLinkedinUrl();
						if ($_linkedinSync !== '' || array_key_exists('linkedin_url', $data)) {
							$_userSync['linkedin_url'] = $_linkedinSync !== '' ? $_linkedinSync : null;
						}
						$_descSync = (string) $model->getDescription();
						if ($_descSync !== '' || array_key_exists('description', $data)) {
							$_userSync['trainer_description'] = $_descSync !== '' ? $_descSync : null;
						}

						// If the trainer's email changed, rewrite the
						// admin_user row's email FIRST (matched by the
						// old value), then continue updating the rest
						// against the new email. Without this step,
						// renaming a trainer's email here would orphan
						// the join from My Profile's perspective.
						if ($_oldTrainerEmail !== ''
							&& $_newTrainerEmail !== ''
							&& $_oldTrainerEmail !== $_newTrainerEmail) {
							$_writeSync->update(
								$_resSync->getTableName('admin/user'),
								array('email' => $_newTrainerEmail),
								array('email = ?' => $_oldTrainerEmail)
							);
						}

						if ($_userSync) {
							$_writeSync->update(
								$_resSync->getTableName('admin/user'),
								$_userSync,
								array('email = ?' => $_lookupEmail)
							);
						}
					}
				} catch (Exception $_revSyncEx) {
					Mage::logException($_revSyncEx);
				}

				Mage::getSingleton('adminhtml/session')->addSuccess(Mage::helper('courses')->__('Item was successfully saved'));
				Mage::getSingleton('adminhtml/session')->setFormData(false);

				if ($this->getRequest()->getParam('back')) {
					$this->_redirect('*/*/edit', array('id' => $model->getId()));
					return;
				}
				$this->_redirect('*/*/');
				return;
            } catch (Exception $e) {
                Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
                Mage::getSingleton('adminhtml/session')->setFormData($data);
                $this->_redirect('*/*/edit', array('id' => $this->getRequest()->getParam('id')));
                return;
            }
        }
        Mage::getSingleton('adminhtml/session')->addError(Mage::helper('courses')->__('Unable to find item to save'));
        $this->_redirect('*/*/');
	}
 
	public function deleteAction() {
		if( $this->getRequest()->getParam('id') > 0 ) {
			try {
				$model = Mage::getModel('courses/providers');
				 
				$model->setId($this->getRequest()->getParam('id'))
					->delete();
					 
				Mage::getSingleton('adminhtml/session')->addSuccess(Mage::helper('adminhtml')->__('Item was successfully deleted'));
				$this->_redirect('*/*/');
			} catch (Exception $e) {
				Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
				$this->_redirect('*/*/edit', array('id' => $this->getRequest()->getParam('id')));
			}
		}
		$this->_redirect('*/*/');
	}

    public function massDeleteAction() {
        $providersIds = $this->getRequest()->getParam('providers');
        if(!is_array($providersIds)) {
			Mage::getSingleton('adminhtml/session')->addError(Mage::helper('adminhtml')->__('Please select item(s)'));
        } else {
            try {
                foreach ($providersIds as $providersId) {
                    $providers = Mage::getModel('courses/providers')->load($providersId);
                    $providers->delete();
                }
                Mage::getSingleton('adminhtml/session')->addSuccess(
                    Mage::helper('adminhtml')->__(
                        'Total of %d record(s) were successfully deleted', count($providersIds)
                    )
                );
            } catch (Exception $e) {
                Mage::getSingleton('adminhtml/session')->addError($e->getMessage());
            }
        }
        $this->_redirect('*/*/index');
    }
	
    public function massStatusAction()
    {
        $providersIds = $this->getRequest()->getParam('providers');
        if(!is_array($providersIds)) {
            Mage::getSingleton('adminhtml/session')->addError($this->__('Please select item(s)'));
        } else {
            try {
                foreach ($providersIds as $providersId) {
                    $providers = Mage::getSingleton('courses/providers')
                        ->load($providersId)
                        ->setStatus($this->getRequest()->getParam('status'))
                        ->setIsMassupdate(true)
                        ->save();
                }
                $this->_getSession()->addSuccess(
                    $this->__('Total of %d record(s) were successfully updated', count($providersIds))
                );
            } catch (Exception $e) {
                $this->_getSession()->addError($e->getMessage());
            }
        }
        $this->_redirect('*/*/index');
    }
  
    public function exportCsvAction()
    {
        $fileName   = 'providers.csv';
        $content    = $this->getLayout()->createBlock('courses/adminhtml_providers_grid')
            ->getCsv();

        $this->_sendUploadResponse($fileName, $content);
    }

    public function exportXmlAction()
    {
        $fileName   = 'providers.xml';
        $content    = $this->getLayout()->createBlock('courses/adminhtml_providers_grid')
            ->getXml();

        $this->_sendUploadResponse($fileName, $content);
    }

    protected function _sendUploadResponse($fileName, $content, $contentType='application/octet-stream')
    {
        $response = $this->getResponse();
        $response->setHeader('HTTP/1.1 200 OK','');
        $response->setHeader('Pragma', 'public', true);
        $response->setHeader('Cache-Control', 'must-revalidate, post-check=0, pre-check=0', true);
        $response->setHeader('Content-Disposition', 'attachment; filename='.$fileName);
        $response->setHeader('Last-Modified', date('r'));
        $response->setHeader('Accept-Ranges', 'bytes');
        $response->setHeader('Content-Length', strlen($content));
        $response->setHeader('Content-type', $contentType);
        $response->setBody($content);
        $response->sendResponse();
        die;
    }
}
