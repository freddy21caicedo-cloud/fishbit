'use client';

import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { CheckSquare, Square, Calendar, Award } from 'lucide-react';
import { PremiumCard } from '../../components/ui/PremiumCard';

interface TaskItem {
  id: string;
  text: string;
  time: string;
  completed: boolean;
  category: 'calidad' | 'alimentacion' | 'mantenimiento';
}

export function TasksChecklist() {
  const [tasks, setTasks] = useState<TaskItem[]>([]);
  const [isLoaded, setIsLoaded] = useState(false);

  // Initialize tasks
  useEffect(() => {
    const defaultTasks: TaskItem[] = [
      { id: '1', text: 'Medición de Calidad del Agua AM (Oxígeno y Temp)', time: '07:00 AM', completed: false, category: 'calidad' },
      { id: '2', text: 'Primera Ración de Alimento a Estanques', time: '08:00 AM', completed: false, category: 'alimentacion' },
      { id: '3', text: 'Segunda Ración de Alimento a Estanques', time: '01:00 PM', completed: false, category: 'alimentacion' },
      { id: '4', text: 'Medición de Calidad del Agua PM (Oxígeno y pH)', time: '05:00 PM', completed: false, category: 'calidad' },
      { id: '5', text: 'Limpieza preventiva de filtros y rejillas', time: '05:30 PM', completed: false, category: 'mantenimiento' }
    ];

    const saved = localStorage.getItem('fishbit_daily_tasks');
    if (saved) {
      try {
        setTasks(JSON.parse(saved));
      } catch {
        setTasks(defaultTasks);
      }
    } else {
      setTasks(defaultTasks);
    }
    setIsLoaded(true);
  }, []);

  // Save tasks to localStorage when updated
  const toggleTask = (id: string) => {
    const updated = tasks.map(t => t.id === id ? { ...t, completed: !t.completed } : t);
    setTasks(updated);
    localStorage.setItem('fishbit_daily_tasks', JSON.stringify(updated));
  };

  const completedCount = tasks.filter(t => t.completed).length;
  const progressPct = tasks.length > 0 ? Math.round((completedCount / tasks.length) * 100) : 0;

  const getCategoryColor = (cat: TaskItem['category']) => {
    switch (cat) {
      case 'calidad': return '#3b82f6';
      case 'alimentacion': return '#8b5cf6';
      case 'mantenimiento': return '#10b981';
      default: return '#64748b';
    }
  };

  if (!isLoaded) {
    return (
      <PremiumCard style={{ padding: '1.5rem', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ color: 'var(--muted-foreground)', fontSize: '0.8rem', fontWeight: 800 }}>Cargando agenda...</div>
      </PremiumCard>
    );
  }

  return (
    <PremiumCard style={{ 
      padding: '1.5rem', 
      background: 'var(--card)',
      border: '1px solid var(--border)',
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'space-between',
      gap: '1rem',
      minHeight: '340px'
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h4 style={{ fontSize: '0.8rem', fontWeight: 900, textTransform: 'uppercase', letterSpacing: '0.05em', color: 'var(--muted-foreground)' }}>
            Agenda Operativa Diaria
          </h4>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', marginTop: '0.2rem' }}>
            <Calendar size={14} color="var(--primary)" />
            <span style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--foreground)' }}>
              Tareas para hoy
            </span>
          </div>
        </div>
        <div style={{ 
          padding: '0.4rem 0.75rem', 
          background: progressPct === 100 ? 'rgba(16, 185, 129, 0.1)' : 'var(--secondary)', 
          color: progressPct === 100 ? '#10b981' : 'var(--primary)', 
          borderRadius: '10px', 
          fontSize: '0.75rem', 
          fontWeight: 900,
          transition: 'all 0.3s ease'
        }}>
          {progressPct}% Listo
        </div>
      </div>

      {/* Progress Bar */}
      <div style={{ width: '100%', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
        <div style={{ width: '100%', height: '8px', background: 'var(--secondary)', borderRadius: '4px', overflow: 'hidden' }}>
          <motion.div
            initial={{ width: 0 }}
            animate={{ width: `${progressPct}%` }}
            transition={{ type: 'spring', stiffness: 80, damping: 15 }}
            style={{
              height: '100%',
              background: progressPct === 100 
                ? 'linear-gradient(90deg, #34d399, #10b981)' 
                : 'linear-gradient(90deg, #2DC9D8, #1B2E5E)',
              borderRadius: '4px'
            }}
          />
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.65rem', fontWeight: 700, color: 'var(--muted-foreground)' }}>
          <span>{completedCount} de {tasks.length} completadas</span>
          {progressPct === 100 && (
            <span style={{ color: '#10b981', display: 'flex', alignItems: 'center', gap: '0.2rem', fontWeight: 900 }}>
              <Award size={12} /> ¡Excelente jornada!
            </span>
          )}
        </div>
      </div>

      {/* Task List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem', flex: 1, overflowY: 'auto', maxHeight: '180px', paddingRight: '4px' }}>
        <AnimatePresence initial={false}>
          {tasks.map((task) => {
            const Icon = task.completed ? CheckSquare : Square;
            const catColor = getCategoryColor(task.category);

            return (
              <motion.div
                key={task.id}
                initial={{ opacity: 0, y: 5 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0 }}
                onClick={() => toggleTask(task.id)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.75rem',
                  padding: '0.6rem 0.75rem',
                  borderRadius: '12px',
                  background: task.completed ? 'var(--secondary)40' : 'var(--secondary)15',
                  border: '1px solid var(--border)50',
                  cursor: 'pointer',
                  transition: 'background 0.2s ease',
                  opacity: task.completed ? 0.7 : 1
                }}
              >
                <div style={{ color: task.completed ? '#10b981' : 'var(--muted-foreground)', display: 'flex', alignItems: 'center' }}>
                  <Icon size={18} />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ 
                    fontSize: '0.75rem', 
                    fontWeight: 750, 
                    color: 'var(--foreground)',
                    textDecoration: task.completed ? 'line-through' : 'none',
                    transition: 'color 0.2s'
                  }}>
                    {task.text}
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', marginTop: '0.1rem' }}>
                    <span style={{ fontSize: '0.6rem', fontWeight: 800, color: 'var(--muted-foreground)' }}>
                      🕒 {task.time}
                    </span>
                    <span style={{ 
                      width: '4px', 
                      height: '4px', 
                      borderRadius: '50%', 
                      background: catColor 
                    }} />
                    <span style={{ fontSize: '0.6rem', fontWeight: 900, color: catColor, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                      {task.category}
                    </span>
                  </div>
                </div>
              </motion.div>
            );
          })}
        </AnimatePresence>
      </div>
    </PremiumCard>
  );
}
