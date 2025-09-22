const express = require('express');
const router = express.Router();
const database = require('../config/database');
const auth = require('../middleware/auth');

// Get all function codes
router.get('/function', auth, async (req, res) => {
    try {
        const functionCodes = await database.all('SELECT * FROM function_codes ORDER BY code');
        res.json(functionCodes);
    } catch (error) {
        console.error('Error fetching function codes:', error);
        res.status(500).json({ message: 'Failed to fetch function codes' });
    }
});

// Get all object codes
router.get('/object', auth, async (req, res) => {
    try {
        const objectCodes = await database.all('SELECT * FROM object_codes ORDER BY code');
        res.json(objectCodes);
    } catch (error) {
        console.error('Error fetching object codes:', error);
        res.status(500).json({ message: 'Failed to fetch object codes' });
    }
});

// Get all codes (both function and object)
router.get('/', auth, async (req, res) => {
    try {
        const functionCodes = await database.all('SELECT *, "Function code" as type FROM function_codes');
        const objectCodes = await database.all('SELECT *, "Object code" as type FROM object_codes');
        
        const allCodes = [...functionCodes, ...objectCodes].sort((a, b) => a.code.localeCompare(b.code));
        
        res.json(allCodes);
    } catch (error) {
        console.error('Error fetching codes:', error);
        res.status(500).json({ message: 'Failed to fetch codes' });
    }
});

// Create a new function code
router.post('/function', auth, async (req, res) => {
    try {
        const { code, description } = req.body;
        
        if (!code || !description) {
            return res.status(400).json({ message: 'Code and description are required' });
        }
        
        // Check if code already exists
        const existing = await database.get('SELECT * FROM function_codes WHERE code = ?', [code]);
        if (existing) {
            return res.status(409).json({ message: 'Function code already exists' });
        }
        
        const result = await database.run(
            'INSERT INTO function_codes (code, description) VALUES (?, ?)',
            [code, description]
        );
        
        res.json({
            id: result.lastID,
            code,
            description,
            type: 'Function code'
        });
    } catch (error) {
        console.error('Error creating function code:', error);
        res.status(500).json({ message: 'Failed to create function code' });
    }
});

// Create a new object code
router.post('/object', auth, async (req, res) => {
    try {
        const { code, description } = req.body;
        
        if (!code || !description) {
            return res.status(400).json({ message: 'Code and description are required' });
        }
        
        // Check if code already exists
        const existing = await database.get('SELECT * FROM object_codes WHERE code = ?', [code]);
        if (existing) {
            return res.status(409).json({ message: 'Object code already exists' });
        }
        
        const result = await database.run(
            'INSERT INTO object_codes (code, description) VALUES (?, ?)',
            [code, description]
        );
        
        res.json({
            id: result.lastID,
            code,
            description,
            type: 'Object code'
        });
    } catch (error) {
        console.error('Error creating object code:', error);
        res.status(500).json({ message: 'Failed to create object code' });
    }
});

// Update a function code
router.put('/function/:id', auth, async (req, res) => {
    try {
        const { id } = req.params;
        const { code, description } = req.body;
        
        const result = await database.run(
            'UPDATE function_codes SET code = ?, description = ? WHERE id = ?',
            [code, description, id]
        );
        
        if (result.changes === 0) {
            return res.status(404).json({ message: 'Function code not found' });
        }
        
        res.json({ message: 'Function code updated successfully' });
    } catch (error) {
        console.error('Error updating function code:', error);
        res.status(500).json({ message: 'Failed to update function code' });
    }
});

// Update an object code
router.put('/object/:id', auth, async (req, res) => {
    try {
        const { id } = req.params;
        const { code, description } = req.body;
        
        const result = await database.run(
            'UPDATE object_codes SET code = ?, description = ? WHERE id = ?',
            [code, description, id]
        );
        
        if (result.changes === 0) {
            return res.status(404).json({ message: 'Object code not found' });
        }
        
        res.json({ message: 'Object code updated successfully' });
    } catch (error) {
        console.error('Error updating object code:', error);
        res.status(500).json({ message: 'Failed to update object code' });
    }
});

// Delete a function code
router.delete('/function/:id', auth, async (req, res) => {
    try {
        const { id } = req.params;
        
        // Check if code is being used in admissions
        const code = await database.get('SELECT code FROM function_codes WHERE id = ?', [id]);
        if (code) {
            const usage = await database.get(
                'SELECT COUNT(*) as count FROM admissions WHERE function_code = ?',
                [code.code]
            );
            
            if (usage.count > 0) {
                return res.status(400).json({ 
                    message: 'Cannot delete function code as it is being used in staff records',
                    usageCount: usage.count
                });
            }
        }
        
        const result = await database.run('DELETE FROM function_codes WHERE id = ?', [id]);
        
        if (result.changes === 0) {
            return res.status(404).json({ message: 'Function code not found' });
        }
        
        res.json({ message: 'Function code deleted successfully' });
    } catch (error) {
        console.error('Error deleting function code:', error);
        res.status(500).json({ message: 'Failed to delete function code' });
    }
});

// Delete an object code
router.delete('/object/:id', auth, async (req, res) => {
    try {
        const { id } = req.params;
        
        // Check if code is being used in admissions
        const code = await database.get('SELECT code FROM object_codes WHERE id = ?', [id]);
        if (code) {
            const usage = await database.get(
                'SELECT COUNT(*) as count FROM admissions WHERE object_code = ?',
                [code.code]
            );
            
            if (usage.count > 0) {
                return res.status(400).json({ 
                    message: 'Cannot delete object code as it is being used in staff records',
                    usageCount: usage.count
                });
            }
        }
        
        const result = await database.run('DELETE FROM object_codes WHERE id = ?', [id]);
        
        if (result.changes === 0) {
            return res.status(404).json({ message: 'Object code not found' });
        }
        
        res.json({ message: 'Object code deleted successfully' });
    } catch (error) {
        console.error('Error deleting object code:', error);
        res.status(500).json({ message: 'Failed to delete object code' });
    }
});

// Generic delete endpoint (determines type by ID)
router.delete('/:id', auth, async (req, res) => {
    try {
        const { id } = req.params;
        
        // First check in function_codes
        const functionCode = await database.get('SELECT * FROM function_codes WHERE id = ?', [id]);
        if (functionCode) {
            // Check usage
            const usage = await database.get(
                'SELECT COUNT(*) as count FROM admissions WHERE function_code = ?',
                [functionCode.code]
            );
            
            if (usage.count > 0) {
                return res.status(400).json({ 
                    message: 'Cannot delete function code as it is being used in staff records',
                    usageCount: usage.count
                });
            }
            
            await database.run('DELETE FROM function_codes WHERE id = ?', [id]);
            return res.json({ message: 'Function code deleted successfully' });
        }
        
        // Then check in object_codes
        const objectCode = await database.get('SELECT * FROM object_codes WHERE id = ?', [id]);
        if (objectCode) {
            // Check usage
            const usage = await database.get(
                'SELECT COUNT(*) as count FROM admissions WHERE object_code = ?',
                [objectCode.code]
            );
            
            if (usage.count > 0) {
                return res.status(400).json({ 
                    message: 'Cannot delete object code as it is being used in staff records',
                    usageCount: usage.count
                });
            }
            
            await database.run('DELETE FROM object_codes WHERE id = ?', [id]);
            return res.json({ message: 'Object code deleted successfully' });
        }
        
        res.status(404).json({ message: 'Code not found' });
    } catch (error) {
        console.error('Error deleting code:', error);
        res.status(500).json({ message: 'Failed to delete code' });
    }
});

module.exports = router;