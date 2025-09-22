const express = require('express');
const database = require('../config/database');
const router = express.Router();
const auth = require('../middleware/auth');

router.get('/', auth, async (req, res) => {
  try {
    const designations = await database.query('SELECT * FROM designations ORDER BY department, name');
    res.json(designations);
  } catch (error) {
    console.error('Get designations error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

router.post('/', auth, async (req, res) => {
  try {
    const { name, department } = req.body;
    
    const result = await database.run(
      'INSERT INTO designations (name, department) VALUES (?, ?)',
      [name, department]
    );

    const newDesignation = await database.query('SELECT * FROM designations WHERE id = ?', [result.id]);
    res.status(201).json(newDesignation[0]);
  } catch (error) {
    console.error('Create designation error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

router.put('/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, department } = req.body;

    await database.run(
      'UPDATE designations SET name = ?, department = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [name, department, id]
    );

    const updatedDesignation = await database.query('SELECT * FROM designations WHERE id = ?', [id]);
    if (updatedDesignation.length === 0) {
      return res.status(404).json({ message: 'Designation not found' });
    }

    res.json(updatedDesignation[0]);
  } catch (error) {
    console.error('Update designation error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

router.delete('/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await database.run('DELETE FROM designations WHERE id = ?', [id]);
    
    if (result.changes === 0) {
      return res.status(404).json({ message: 'Designation not found' });
    }

    res.json({ message: 'Designation deleted successfully' });
  } catch (error) {
    console.error('Delete designation error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;